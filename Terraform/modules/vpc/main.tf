resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "public_subnet_1" {
  name          = "${var.environment}-public-subnet-1"
  ip_cidr_range = var.public_subnet_1_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "public_subnet_2" {
  name          = "${var.environment}-public-subnet-2"
  ip_cidr_range = var.public_subnet_2_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "private_subnet_1" {
  name          = "${var.environment}-private-subnet-1"
  ip_cidr_range = var.private_subnet_1_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet_2" {
  name          = "${var.environment}-private-subnet-2"
  ip_cidr_range = var.private_subnet_2_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  
  private_ip_google_access = true
}

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