output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "private_subnet_1_name" {
  value = google_compute_subnetwork.private_1.name
}

output "pod_range_name" {
  value = "pod-range"
}

output "svc_range_name" {
  value = "svc-range"
}
