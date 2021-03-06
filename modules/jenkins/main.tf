resource "random_id" "random_16" {
	byte_length = 16 * 3 / 4
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
	passwords = {
		admin    = random_id.random_16.b64_url
		candidat = random_string.suffix.result
	}
}

resource "local_file" "kube_config" {
    content     = var.kubeconfig 
    filename    = "kubeconfig.yaml"
}


resource "helm_release" "jenkins" {
 	 name  = "jenkins"
         repository = "https://kubernetes-charts.storage.googleapis.com/"
  	 chart = "jenkins"
         version = "2.1.0"

         values = ["${file("${path.module}/values.yaml")}"]

	 set {
		 name  = "master.JCasC.configScripts.securityrealm"
		 value = templatefile("${path.module}/jenkins-securityrealm.yaml", local.passwords)
         }
	
         set {
                 name  = "master.JCasC.configScripts.authorizationstrategy"
                 value = file("${path.module}/jenkins-authorizationstrategy.yaml")
         }
}

data "kubernetes_service" "jenkins" {
  metadata {
    name = "jenkins"
  }
  depends_on = [helm_release.jenkins]
}
