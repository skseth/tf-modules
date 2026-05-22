terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = ">=0.9.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=3.0.1" # Example, check the HashiCorp Registry for the latest
    }    
  }
}
