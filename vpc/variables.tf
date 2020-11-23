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