module "cluster" {
	source = "./modules/cluster"
}

module "jenkins" {
	source = "./modules/jenkins"

	kubeconfig = module.cluster.kubeconfig
}


