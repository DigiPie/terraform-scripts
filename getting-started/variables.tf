variable "region" {
  default = "ap-southeast-1"
}

variable "amis" {
  type = map(string)
  default = {
    "ap-southeast-1" = "ami-03faaf9cde2b38e9f"
  }
}

output "ip" {
  value = aws_eip.ip.public_ip
}
