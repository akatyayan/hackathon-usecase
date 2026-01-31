output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "private_subnet_1_name" {
  value = google_compute_subnetwork.private_subnet_1.name
}

output "network_id" {
  value = google_compute_network.vpc.id
}
