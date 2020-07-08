data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "vpc-${var.namespace}"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  public_subnet_tags = {
    "kubernetes.io/cluster/eks-${var.namespace}" = "owned"
    "kubernetes.io/role/elb"			  = ""
  }
  enable_dns_hostnames = true
}



