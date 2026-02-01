terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = null # passed via -backend-config in CI
    prefix = null # passed via -backend-config in CI
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

module "gke" {
  source = "../../modules/gke"

  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  vpc_name       = module.vpc.vpc_name
  subnet_name    = module.vpc.private_subnet_1_name
  pod_range_name = module.vpc.pod_range_name
  svc_range_name = module.vpc.svc_range_name
  node_count     = 2
  machine_type   = "e2-medium"
}

module "secrets" {
  source = "../../modules/secrets"

  project_id  = var.project_id
  environment = var.environment
}

output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value     = module.gke.cluster_endpoint
  sensitive = true
}
