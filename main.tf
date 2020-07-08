module "jenkins" {
        source = "./modules/jenkins"

        kubeconfig  = module.cluster.kubeconfig
}

module "cluster" {
        source = "./modules/cluster"

        namespace = var.namespace
        vpc       = module.network.vpc
}

module "network" {
        source = "./modules/network"
  
        namespace = var.namespace
}

