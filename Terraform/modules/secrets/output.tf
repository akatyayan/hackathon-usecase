output "patient_secret_id" {
  value = google_secret_manager_secret.patient_secret.secret_id
}

output "appointment_secret_id" {
  value = google_secret_manager_secret.appointment_secret.secret_id
}