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

### Subnets
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

### Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}.internet_gateway"
  }
}

### Public routes
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
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

### ELB security group
resource "aws_security_group" "elb_security_group" {
  description = "Enable TCP ingress from the Internet, and TCP egress to the App SG"
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

### App security group
resource "aws_security_group" "app_security_group" {
  description = "Enable TCP ingress from the ELB SG, and SSH ingress from the Bastion SG"
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

### Bastion security group
resource "aws_security_group" "bastion_security_group" {
  description = "Enable SSH ingress from var.bastion_ssh_cidr, SSH egress to the App SG, and TCP egress on var.db_port to the DB SG"
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

### DB security group
resource "aws_security_group" "db_security_group" {
  description = "Enable TCP ingress on var.db_port from the App SG and the Bastion SG, and TCP egress on var.db_port to the Internet"
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

### NAT gateway for private subnets
resource "aws_nat_gateway" "nat_gateway_az_1" {
  allocation_id = aws_eip.eip_nat_az_1.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.vpc_name}.nat_gateway_az_1"
  }
}

# Only created if is production infrastructure
resource "aws_nat_gateway" "nat_gateway_az_2" {
  count         = var.is_production ? 1 : 0
  allocation_id = aws_eip.eip_nat_az_2[0].id
  subnet_id     = aws_subnet.public_subnet_2.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.vpc_name}.nat_gateway_az_2"
  }
}

resource "aws_eip" "eip_nat_az_1" {
  vpc = true

  tags = {
    Name = "${var.vpc_name}.eip_nat_az_1"
  }
}

# Only created if is production infrastructure
resource "aws_eip" "eip_nat_az_2" {
  count = var.is_production ? 1 : 0
  vpc   = true

  tags = {
    Name = "${var.vpc_name}.eip_nat_az_2"
  }
}

### Private routes
resource "aws_route_table" "private_subnet_1_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway_az_1.id
  }

  tags = {
    Name = "${var.vpc_name}.private_subnet_1_route_table"
  }
}

# Only created if is production infrastructure
resource "aws_route_table" "private_subnet_2_route_table" {
  count  = var.is_production ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway_az_2[0].id
  }

  tags = {
    Name = "${var.vpc_name}.private_subnet_2_route_table"
  }
}

resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_subnet_1_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  subnet_id = aws_subnet.private_subnet_2.id
  # If production use separate route table; else use same route table
  route_table_id = var.is_production ? aws_route_table.private_subnet_2_route_table[0].id : aws_route_table.private_subnet_1_route_table.id
}