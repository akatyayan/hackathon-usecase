terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-terraform-state"
    prefix = "test/state"
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
  
  project_id            = var.project_id
  environment           = "dev"
  region                = var.region
  public_subnet_1_cidr  = "10.0.1.0/24"
  public_subnet_2_cidr  = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.11.0/24"
  private_subnet_2_cidr = "10.0.12.0/24"
}

module "gke" {
  source = "../../modules/gke"
  
  project_id     = var.project_id
  environment    = "dev"
  region         = var.region
  vpc_name       = module.vpc.vpc_name
  subnet_name    = module.vpc.private_subnet_1_name
  node_count     = 2
  min_node_count = 2
  max_node_count = 5
  machine_type   = "e2-medium"
}

module "iam" {
  source = "../../modules/iam"
  
  project_id  = var.project_id
  environment = "dev"
}

module "secrets" {
  source = "../../modules/secrets"
  
  project_id  = var.project_id
  environment = "dev"
  secrets = {
    database_url = "postgresql://localhost:5432/dev"
    api_key      = "dev-api-key-placeholder"
  }
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"
  
  project_id     = var.project_id
  region         = var.region
  repository_id  = "hackathon-apps"
}