provider "aws" {
	region = var.region
}

provider "helm" {
 	 kubernetes {
    		config_path = "kubeconfig.yaml"
  	 }
}
