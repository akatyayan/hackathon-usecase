resource "google_container_cluster" "primary" {
  name     = "${var.environment}-gke-cluster"
  location = var.region
  project  = var.project_id
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.vpc_name
  subnetwork = var.subnet_name
  
  # ============================================
  # MONITORING CONFIGURATION
  # ============================================
  
  # Enable Cloud Monitoring and Logging
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    
    # Enable managed Prometheus for application metrics
    managed_prometheus {
      enabled = true
    }
  }
  
  # Resource usage monitoring
  resource_usage_export_config {
    enable_network_egress_metering = true
    enable_resource_consumption_metering = true
    
    bigquery_destination {
      dataset_id = google_bigquery_dataset.gke_usage.dataset_id
    }
  }
  
  # Workload Identity for secure metrics access
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }
}

# BigQuery dataset for resource usage export
resource "google_bigquery_dataset" "gke_usage" {
  dataset_id = "${var.environment}_gke_resource_usage"
  project    = var.project_id
  location   = var.region
  
  description = "GKE resource usage metrics"
  
  default_table_expiration_ms = 2592000000 # 30 days
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
    disk_type    = "pd-standard"
    
    # Resource labels for monitoring
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
    
    # Monitoring and logging scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    tags = ["${var.environment}-gke-node"]
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}