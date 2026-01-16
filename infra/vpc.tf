resource "aws_vpc" "eks_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = var.aws_vpc_name
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                                        = var.public_subnet_1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                                        = var.public_subnet_2
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name                                        = var.private_subnet_1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name                                        = var.private_subnet_2
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = var.internet_gateway
  }
}
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = var.elastic_ip
  }
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip.id
  tags = {
    Name = var.nat_gateway
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.public_route_table
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = var.private_route_table
  }
}

resource "aws_route_table_association" "public_rt_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "cluster_sg" {
  name   = var.cluster_security_group
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = var.cluster_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ingress_from_nodes" {
  security_group_id            = aws_security_group.cluster_sg.id
  referenced_security_group_id = aws_security_group.node_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ingress_from_admin" {
  security_group_id = aws_security_group.cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "cluster_egress" {
  security_group_id = aws_security_group.cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "node_sg" {
  name   = var.node_security_group
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = var.node_security_group
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_ingress_from_node" {
  security_group_id            = aws_security_group.node_sg.id
  referenced_security_group_id = aws_security_group.node_sg.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "node_ingress_from_vpc" {
  security_group_id = aws_security_group.node_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = aws_vpc.eks_vpc.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "node_ingress_from_cluster" {
  security_group_id            = aws_security_group.node_sg.id
  referenced_security_group_id = aws_security_group.cluster_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 65535
}

resource "aws_vpc_security_group_egress_rule" "node_egress" {
  security_group_id = aws_security_group.node_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
