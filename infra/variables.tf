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

variable "cluster_security_group" {
  type        = string
  description = "cluster security group name"
}

variable "node_security_group" {
  type        = string
  description = "node security group name"
}

variable "cluster_name" {
  type        = string
  description = "eks cluster name"
}

variable "cluster_role_name" {
  type        = string
  description = "eks cluster role name"
}

variable "node_group_name" {
  type        = string
  description = "eks worker node group name"
}

variable "worker_role_name" {
  type        = string
  description = "eks worker role name"
}
