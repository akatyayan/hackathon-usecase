resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Public Subnet - Zone 1
resource "google_compute_subnetwork" "public_1" {
  name          = "${var.environment}-public-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# Public Subnet - Zone 2
resource "google_compute_subnetwork" "public_2" {
  name          = "${var.environment}-public-subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# Private Subnet - Zone 1
resource "google_compute_subnetwork" "private_1" {
  name                     = "${var.environment}-private-subnet-1"
  ip_cidr_range            = "10.0.11.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true

  # GKE secondary ranges
  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "svc-range"
    ip_cidr_range = "192.168.2.0/24"
  }
}

# Private Subnet - Zone 2
resource "google_compute_subnetwork" "private_2" {
  name                     = "${var.environment}-private-subnet-2"
  ip_cidr_range            = "10.0.12.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true
}

# NAT Gateway for private subnets
resource "google_compute_router" "router" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
}

# Firewall - Allow internal
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
}

# Firewall - Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http" {
  name    = "${var.environment}-allow-http"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.environment}-gke-node"]
}
