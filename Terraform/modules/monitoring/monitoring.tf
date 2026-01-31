terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================
# Notification Channels
# ============================================

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.environment}-cpu-memory-alerts"
  type         = "email"
  project      = var.project_id
  
  labels = {
    email_address = var.alert_email
  }
  
  user_labels = {
    environment = var.environment
  }
}

resource "google_monitoring_notification_channel" "slack" {
  count        = var.slack_webhook_url != "" ? 1 : 0
  display_name = "${var.environment}-slack-alerts"
  type         = "slack"
  project      = var.project_id
  
  labels = {
    channel_name = var.slack_channel
  }
  
  sensitive_labels {
    auth_token = var.slack_webhook_url
  }
}

# ============================================
# Custom Metrics Descriptors
# ============================================

resource "google_monitoring_metric_descriptor" "app_cpu_usage" {
  description  = "Application CPU usage percentage"
  display_name = "Application CPU Usage"
  type         = "custom.googleapis.com/application/cpu/usage"
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  project      = var.project_id
  
  labels {
    key         = "service_name"
    value_type  = "STRING"
    description = "Name of the service"
  }
  
  labels {
    key         = "environment"
    value_type  = "STRING"
    description = "Environment (dev/staging/prod)"
  }
}

resource "google_monitoring_metric_descriptor" "app_memory_usage" {
  description  = "Application memory usage in bytes"
  display_name = "Application Memory Usage"
  type         = "custom.googleapis.com/application/memory/usage"
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  unit         = "By"
  project      = var.project_id
  
  labels {
    key         = "service_name"
    value_type  = "STRING"
    description = "Name of the service"
  }
  
  labels {
    key         = "environment"
    value_type  = "STRING"
    description = "Environment (dev/staging/prod)"
  }
}