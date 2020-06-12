data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "ci-cd-eks-spot-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
