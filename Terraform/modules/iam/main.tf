resource "google_service_account" "gke_sa" {
  account_id   = "${var.environment}-gke-sa"
  display_name = "GKE Service Account for ${var.environment}"
  project      = var.project_id
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}