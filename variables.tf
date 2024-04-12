variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones in the region"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "existing_vpc_id" {
  description = "Exist VPC ID"
  type        = string
}

variable "existing_subnet_cidr" {
  description = "existing_subnet_cidr"
  type        = string
}

variable "existing_route_id"{
  description = "existing_subnet_id"
  type        = string
}