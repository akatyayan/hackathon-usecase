resource "google_secret_manager_secret" "patient_secret" {
  secret_id = "${var.environment}-patient-service-secret"
  project   = var.project_id

  replication {
    automatic {}
  }
}

resource "google_secret_manager_secret_version" "patient_secret_version" {
  secret      = google_secret_manager_secret.patient_secret.id
  secret_data = "patient-secret-value"
}

resource "google_secret_manager_secret" "appointment_secret" {
  secret_id = "${var.environment}-appointment-service-secret"
  project   = var.project_id

  replication {
    automatic {}
  }
}

resource "google_secret_manager_secret_version" "appointment_secret_version" {
  secret      = google_secret_manager_secret.appointment_secret.id
  secret_data = "appointment-secret-value"
}