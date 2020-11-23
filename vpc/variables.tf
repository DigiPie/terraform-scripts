variable "region" {
  default = "ap-southeast-1"
}

variable "az" {
  type = map(string)
  default = {
    "Public1" = "ap-southeast-1a",
    "Public2" = "ap-southeast-1b"
  }
}

variable "vpc_name" {
  default = "vpc"
}

variable "vpc_cidr_map" {
  type = map(string)
  default = {
    "VPC"      = "10.50.0.0/16",
    "Public1"  = "10.50.0.0/24",
    "Public2"  = "10.50.1.0/24",
    "Private1" = "10.50.64.0/19",
    "Private2" = "10.50.96.0/19"
  }
}

output "VPC_Id" {
  value = aws_vpc.main.id
}

output "VPC_CIDR" {
  value = aws_vpc.main.cidr_block
}

output "PublicSubnet1_Id" {
  value = aws_subnet.public1.id
}

output "PublicSubnet1_CIDR" {
  value = aws_subnet.public1.cidr_block
}

output "PublicSubnet2_Id" {
  value = aws_subnet.public2.id
}

output "PublicSubnet2_CIDR" {
  value = aws_subnet.public2.cidr_block
}