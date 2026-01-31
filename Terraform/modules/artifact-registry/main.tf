resource "google_artifact_registry_repository" "apps" {
  location      = var.region
  repository_id = var.repository_id
  description   = "Container images for hackathon microservices"
  format        = "DOCKER"
  project       = var.project_id
}

output "repository_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.apps.repository_id}"
}

output "repository_id" {
  value = google_artifact_registry_repository.apps.repository_id
}
