terraform {
	required_version   = ">= 0.12.2"
 	required_providers {
		aws	 = ">= 2.28.1"
		local    = "~> 1.2"
		random   = "~> 2.1"
		template = "~> 2.1"
		null     = "~> 2.1"
		helm	 = "~> 1.2.3"
	}
}	
