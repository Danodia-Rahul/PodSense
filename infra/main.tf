module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "podsense-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = []

  enable_nat_gateway = false
  create_igw         = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" : "1"
  }

  tags = {
    Environment = "lab"
    Terraform   = "true"
    "kubernetes.io/cluster/eks-lab" : "shared"
  }
}
