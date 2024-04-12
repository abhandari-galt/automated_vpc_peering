resource "aws_vpc" "locust_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "LocustVPC-${random_string.postfix.result}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.locust_vpc.id
  tags = {
    Name = "LocustIGW-${random_string.postfix.result}"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.locust_vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "LocustPublicSubnet-${count.index}-${random_string.postfix.result}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.locust_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "LocustPrivateSubnet-${count.index}-${random_string.postfix.result}"
  }
}

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "LocustEIPForNAT-${random_string.postfix.result}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "LocustNATGateway-${random_string.postfix.result}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.locust_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "LocustPublicRT-${random_string.postfix.result}"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(aws_subnet.public_subnet.*.id)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.locust_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "LocustPrivateRT-${random_string.postfix.result}"
  }
}

resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private_subnet.*.id)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
