terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.43"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
  region  = var.aws_region
  default_tags {   
    tags = {     
      Environment = "Dev"     
      Owner       = "PTI Team"     
      Project     = "Performance Testing Improvements"   
      terraform   = "True"
    } 
  }
}

resource "random_string" "postfix" {
  length  = 4
  special = false
  upper   = false
}
