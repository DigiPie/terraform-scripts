terraform {
  backend "remote" {
    organization = "digipie"

    workspaces {
      name = "example-workspace"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_map["VPC"]
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["Public1"]
  availability_zone = var.az["Public1"]

  tags = {
    Name = "${var.vpc_name}.public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["Public2"]
  availability_zone = var.az["Public2"]

  tags = {
    Name = "${var.vpc_name}.public2"
  }
}