data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "eks-${var.namespace}"
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  subnets      = var.vpc.public_subnets
  vpc_id       = var.vpc.vpc_id
  
  worker_groups = [
    {
      name                = "on-demand-1"
      instance_type       = "t2.medium"
      asg_max_size        = 1
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=normal"
      suspended_processes = ["AZRebalance"]
    },
    {
      name                = "spot-1"
      spot_price          = "0.015"
      instance_type       = "t2.medium"
      asg_max_size        = 1
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=spot"
      suspended_processes = ["AZRebalance"]
    }
  ]
}

