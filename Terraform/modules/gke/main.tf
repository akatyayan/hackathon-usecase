resource "google_container_cluster" "primary" {
  name     = "${var.environment}-gke-cluster"
  location = var.region
  project  = var.project_id
  
  # We can't create a cluster with no node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.vpc_name
  subnetwork = var.subnet_name
  
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Enable logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.environment}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  project    = var.project_id
  
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      environment = var.environment
    }
    
    tags = ["${var.environment}-gke-node"]
  }
}