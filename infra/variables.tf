variable "aws_vpc_name" {
  type        = string
  description = "VPC name"
}

variable "public_subnet_1" {
  type        = string
  description = "public subnet 1 name"
}

variable "public_subnet_2" {
  type        = string
  description = "public subnet 2 name"
}

variable "private_subnet_1" {
  type        = string
  description = "private sunbnet 1 name"
}

variable "private_subnet_2" {
  type        = string
  description = "private subnet 2 name"
}

variable "internet_gateway" {
  type        = string
  description = "internet gateway name"
}

variable "nat_gateway" {
  type        = string
  description = "nat gateway name"
}

variable "elastic_ip" {
  type        = string
  description = "elastic ip address name"
}

variable "public_route_table" {
  type        = string
  description = "public route table name"
}

variable "private_route_table" {
  type        = string
  description = "private route table name"
}

variable "security_group" {
  type        = string
  description = "security group name"
}
