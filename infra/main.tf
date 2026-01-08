module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "podsense-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  create_igw         = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" : "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" : "1"
  }
  tags = {
    Environment = "lab"
    Terraform   = "true"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>21.0"

  name               = "podsense-eks"
  kubernetes_version = "1.33"

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = "lab"
    Terraform   = "true"
  }

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.small"]
    }
  }
}
