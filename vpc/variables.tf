variable "region" {
  default = "ap-southeast-1"
}

variable "az" {
  type = map(string)
  default = {
    "az_1" = "ap-southeast-1a",
    "az_2" = "ap-southeast-1b"
  }
}

variable "vpc_name" {
  default = "vpc"
}

variable "vpc_cidr_map" {
  type = map(string)
  default = {
    "vpc"              = "10.50.0.0/16",
    "public_subnet_1"  = "10.50.0.0/24",
    "public_subnet_2"  = "10.50.1.0/24",
    "private_subnet_1" = "10.50.64.0/19",
    "private_subnet_2" = "10.50.96.0/19"
  }
}

variable "bastion_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "db_port" {
  type    = number
  default = 3306 # MySQL port: 3306, PSQL port: 5432
}

variable "elb_ingress_port" {
  type    = number
  default = 80
}

variable "app_ingress_port" {
  type    = number
  default = 80
}


output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id
}

output "public_subnet_1_cidr" {
  value = aws_subnet.public_subnet_1.cidr_block
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id
}

output "public_subnet_2_cidr" {
  value = aws_subnet.public_subnet_2.cidr_block
}

output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1.id
}

output "private_subnet_1_cidr" {
  value = aws_subnet.private_subnet_1.cidr_block
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id
}

output "private_subnet_2_cidr" {
  value = aws_subnet.private_subnet_2.cidr_block
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "elb_security_group_id" {
  value = aws_security_group.elb_security_group.id
}

output "app_security_group_id" {
  value = aws_security_group.app_security_group.id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_security_group.id
}

output "db_security_group_id" {
  value = aws_security_group.db_security_group.id
}

output "elb_ingress_port" {
  value = var.elb_ingress_port
}

output "app_ingress_port" {
  value = var.app_ingress_port
}