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
  cidr_block           = var.vpc_cidr_map["vpc"]
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["public_subnet_1"]
  availability_zone = var.az["az_1"]

  tags = {
    Name = "${var.vpc_name}.public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["public_subnet_2"]
  availability_zone = var.az["az_2"]

  tags = {
    Name = "${var.vpc_name}.public_subnet_2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["private_subnet_1"]
  availability_zone = var.az["az_1"]

  tags = {
    Name = "${var.vpc_name}.private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.vpc_cidr_map["private_subnet_2"]
  availability_zone = var.az["az_2"]

  tags = {
    Name = "${var.vpc_name}.private_subnet_2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}.internet_gateway"
  }
}

# Public routes
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.vpc_name}.public_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# ELB security group
resource "aws_security_group" "elb_security_group" {
  description = "Enable HTTP/HTTPs ingress"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}.elb_security_group"
  }
}

resource "aws_security_group_rule" "elb_sg_ingress_from_internet" {
  security_group_id = aws_security_group.elb_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.elb_ingress_port
  to_port           = var.elb_ingress_port
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "elb_sg_egress_to_app" {
  security_group_id        = aws_security_group.elb_security_group.id
  source_security_group_id = aws_security_group.app_security_group.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.app_ingress_port
  to_port                  = var.app_ingress_port
}

# App security group
resource "aws_security_group" "app_security_group" {
  description = "Enable access from ELB to app"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}.app_security_group"
  }
}

resource "aws_security_group_rule" "app_sg_ingress_from_elb" {
  security_group_id        = aws_security_group.app_security_group.id
  source_security_group_id = aws_security_group.elb_security_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.app_ingress_port
  to_port                  = var.app_ingress_port
}

resource "aws_security_group_rule" "app_sg_ingress_from_bastion_ssh" {
  security_group_id        = aws_security_group.app_security_group.id
  source_security_group_id = aws_security_group.bastion_security_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
}

# Bastion security group
resource "aws_security_group" "bastion_security_group" {
  description = "Enable access to the bastion host"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}.bastion_security_group"
  }
}

resource "aws_security_group_rule" "bastion_sg_ingress_from_cidr_ssh" {
  security_group_id = aws_security_group.bastion_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.bastion_ssh_cidr
}

resource "aws_security_group_rule" "bastion_sg_egress_to_internet_http" {
  security_group_id = aws_security_group.bastion_security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_sg_egress_to_internet_https" {
  security_group_id = aws_security_group.bastion_security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_sg_egress_to_internet_ntp" {
  security_group_id = aws_security_group.bastion_security_group.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 123
  to_port           = 123
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_sg_egress_to_app" {
  security_group_id        = aws_security_group.bastion_security_group.id
  source_security_group_id = aws_security_group.app_security_group.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
}

resource "aws_security_group_rule" "bastion_sg_egress_to_db" {
  security_group_id        = aws_security_group.bastion_security_group.id
  source_security_group_id = aws_security_group.db_security_group.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.db_port
  to_port                  = var.db_port
}

# DB security group
resource "aws_security_group" "db_security_group" {
  description = "Enable access to the RDS DB"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}.db_security_group"
  }
}

resource "aws_security_group_rule" "db_sg_ingress_from_app" {
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.app_security_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.db_port
  to_port                  = var.db_port
}

resource "aws_security_group_rule" "db_sg_ingress_from_bastion" {
  security_group_id        = aws_security_group.db_security_group.id
  source_security_group_id = aws_security_group.bastion_security_group.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.db_port
  to_port                  = var.db_port
}

resource "aws_security_group_rule" "db_sg_egress_to_internet" {
  security_group_id = aws_security_group.db_security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.db_port
  to_port           = var.db_port
  cidr_blocks       = ["0.0.0.0/0"]
}