module "cluster" {
	source = "./modules/cluster"
}

module "jenkins" {
	source = "./modules/jenkins"

	kubeconfig  = module.cluster.kubeconfig
        lb_dns_name = module.cluster.lb_dns_name
}


