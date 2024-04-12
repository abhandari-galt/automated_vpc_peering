resource "aws_iam_role" "lambda_role" {
  name = "VPCPeeringLambdaRole-${random_string.postfix.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "VPCPeeringLambdaPolicy-${random_string.postfix.result}"
  role = aws_iam_role.lambda_role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_vpc_peering_connection" "locust_peer" {
  vpc_id      = aws_vpc.locust_vpc.id
  peer_vpc_id = var.existing_vpc_id
  auto_accept = true

  tags = {
    Name = "Peering-LocustVPC-${random_string.postfix.result}"
  }
}

resource "aws_route" "private_peer_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = var.existing_subnet_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.locust_peer.id
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpc_peering_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.vpc_peering_creation_rule.arn
}

resource "aws_cloudwatch_event_rule" "vpc_peering_creation_rule" {
  name        = "VpcPeeringCreationRule-${random_string.postfix.result}"
  description = "Trigger Lambda when VPC peering connection is created"
  event_pattern = jsonencode({
    source: ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    detail: {
      eventSource: ["ec2.amazonaws.com"],
      eventName: ["CreateVpcPeeringConnection"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.vpc_peering_creation_rule.name
  arn       = aws_lambda_function.vpc_peering_lambda.arn
}


data "archive_file" "vpc_peering_lambda" {
  type        = "zip"
  source_file = "vpc_peering_routes.py"
  output_path = "vpc_peering_routes.zip"
}

resource "aws_lambda_function" "vpc_peering_lambda" {
  filename         = data.archive_file.vpc_peering_lambda.output_path
  function_name    = "VPCPeeringLambda-${random_string.postfix.result}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "vpc_peering_routes.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.vpc_peering_lambda.output_base64sha256

  environment {
    variables = {
      ROUTE_TABLE_ID = var.existing_route_id
    }
  }
}

resource "null_resource" "delete_route" {
  triggers = {
    route_id = var.existing_route_id
    cidr_range = var.cidr_block
    region = var.aws_region
  }

  provisioner "local-exec" {
    command = "aws ec2 delete-route --route-table-id ${self.triggers.route_id} --destination-cidr-block ${self.triggers.cidr_range} --region ${self.triggers.region}"
    when    = destroy
  }
}