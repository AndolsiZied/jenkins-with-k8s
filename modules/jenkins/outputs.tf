output "passwords" {
	value = local.passwords
}

output "jenkins_svc" {
	value = data.kubernetes_service.jenkins.load_balancer_ingress.0.hostname
}
