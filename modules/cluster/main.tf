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
  cluster_name = "ci-cd-cluster-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "eks-vpc-spot"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/elb"			  = ""
  }
  enable_dns_hostnames = true
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg_${local.cluster_name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
   "kubernetes.io/cluster/${local.cluster_name}" = "shared"
   "kubernetes.io/role/elb"			 = "1"
  }
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name 		                = "${local.cluster_name}-alb"
  load_balancer_type            = "application"
  security_groups    		= [aws_security_group.lb_sg.id]
  subnets            		= module.vpc.public_subnets
  vpc_id             		= module.vpc.vpc_id
  http_tcp_listeners 		= [{
					port = 80, 
					protocol = "HTTP" 
				  }]
  target_groups  		= [{
      					name_prefix      = "eks-"
      					backend_protocol = "HTTP"
      					backend_port     = 30934
      					target_type      = "instance"
    				   }]
  tags = {
   	"kubernetes.io/cluster/${local.cluster_name}" = "owned"
   	"kubernetes.io/service-name"                  = "default/jenkins"
  } 
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  subnets      = module.vpc.public_subnets
  vpc_id       = module.vpc.vpc_id
  
  worker_groups = [
    {
      name                = "on-demand-1"
      instance_type       = "t2.micro"
      asg_max_size        = 1
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=normal"
      target_group_arns   = module.alb.target_group_arns
      suspended_processes = ["AZRebalance"]
    },
    {
      name                = "spot-1"
      spot_price          = "0.0045"
      instance_type       = "t2.micro"
      asg_max_size        = 1
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=spot"
      target_group_arns   = module.alb.target_group_arns
      suspended_processes = ["AZRebalance"]
    }
  ]
}

