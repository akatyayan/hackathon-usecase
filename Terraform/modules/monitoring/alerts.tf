# ============================================
# CPU Alert Policies
# ============================================

# Alert: High CPU Usage on Pods
resource "google_monitoring_alert_policy" "pod_high_cpu" {
  display_name = "${var.environment}-pod-high-cpu-usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Pod CPU usage above 80%"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_container"
        AND resource.labels.namespace_name = "healthcare-app"
        AND metric.type = "kubernetes.io/container/cpu/core_usage_time"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields = [
          "resource.labels.pod_name",
          "resource.labels.container_name"
        ]
      }
      
      trigger {
        count = 1
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
    
    notification_rate_limit {
      period = "300s"
    }
  }
  
  documentation {
    content   = <<-EOT
      ## High CPU Usage Alert
      
      **Severity**: Warning
      **Environment**: ${var.environment}
      
      **Description**: Pod CPU usage has exceeded 80% for more than 5 minutes.
      
      **Impact**: Application performance may be degraded.
      
      **Action Items**:
      1. Check pod logs: `kubectl logs -n healthcare-app <pod-name>`
      2. Check resource usage: `kubectl top pods -n healthcare-app`
      3. Consider scaling horizontally (HPA should auto-scale)
      4. Review application code for CPU-intensive operations
      5. Check for resource limits: `kubectl describe pod <pod-name> -n healthcare-app`
      
      **Runbook**: https://runbooks.example.com/high-cpu
    EOT
    mime_type = "text/markdown"
  }
}

# Alert: Node High CPU Usage
resource "google_monitoring_alert_policy" "node_high_cpu" {
  display_name = "${var.environment}-node-high-cpu-usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Node CPU usage above 85%"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_node"
        AND metric.type = "kubernetes.io/node/cpu/allocatable_utilization"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.node_name"]
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content   = <<-EOT
      ## High Node CPU Usage
      
      **Severity**: Critical
      **Environment**: ${var.environment}
      
      **Impact**: Node is near CPU capacity. New pods may not be scheduled.
      
      **Actions**:
      1. Check node status: `kubectl describe node <node-name>`
      2. Review pod distribution: `kubectl get pods -A -o wide`
      3. Cluster Autoscaler should add nodes automatically
      4. Manually scale if needed: `gcloud container clusters resize ...`
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================
# Memory Alert Policies
# ============================================

# Alert: High Memory Usage on Pods
resource "google_monitoring_alert_policy" "pod_high_memory" {
  display_name = "${var.environment}-pod-high-memory-usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Pod memory usage above 85%"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_container"
        AND resource.labels.namespace_name = "healthcare-app"
        AND metric.type = "kubernetes.io/container/memory/used_bytes"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields = [
          "resource.labels.pod_name",
          "resource.labels.container_name"
        ]
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content   = <<-EOT
      ## High Memory Usage Alert
      
      **Severity**: Warning
      **Environment**: ${var.environment}
      
      **Impact**: Pod may be OOM killed soon.
      
      **Actions**:
      1. Check memory usage: `kubectl top pods -n healthcare-app`
      2. Review pod logs for memory leaks
      3. Check for memory limits: `kubectl describe pod <pod-name> -n healthcare-app`
      4. Consider increasing memory requests/limits
      5. Look for recent OOM kills: `kubectl get events -n healthcare-app | grep OOM`
    EOT
    mime_type = "text/markdown"
  }
}

# Alert: Pod OOM Killed
resource "google_monitoring_alert_policy" "pod_oom_killed" {
  display_name = "${var.environment}-pod-oom-killed"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Pod killed due to OOM"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_container"
        AND resource.labels.namespace_name = "healthcare-app"
        AND metric.type = "kubernetes.io/container/restart_count"
      EOT
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = ["resource.labels.pod_name"]
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content   = <<-EOT

      1. Check pod events: `kubectl describe pod <pod-name> -n healthcare-app`
      2. Review memory limits immediately
      3. Increase memory requests/limits in deployment
      4. Check for memory leaks in application code
      5. Review recent code changes
    EOT
    mime_type = "text/markdown"
  }
}

# Alert: Node High Memory
resource "google_monitoring_alert_policy" "node_high_memory" {
  display_name = "${var.environment}-node-high-memory-usage"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "Node memory usage above 90%"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_node"
        AND metric.type = "kubernetes.io/node/memory/allocatable_utilization"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.90
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.labels.node_name"]
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email.id],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].id] : []
  )
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content   = <<-EOT
      ## Critical Node Memory Usage
      
      **Severity**: Critical
      **Environment**: ${var.environment}
      
      **Impact**: Node memory exhaustion imminent. May cause pod evictions.
      
      **Actions**:
      1. Check node status immediately
      2. Review pod memory requests
      3. Scale cluster if needed
      4. Check for memory-intensive pods: `kubectl top pods -A --sort-by=memory`
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================
# CPU Throttling Alert
# ============================================

resource "google_monitoring_alert_policy" "cpu_throttling" {
  display_name = "${var.environment}-cpu-throttling"
  project      = var.project_id
  combiner     = "OR"
  
  conditions {
    display_name = "CPU throttling detected"
    
    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_container"
        AND resource.labels.namespace_name = "healthcare-app"
        AND metric.type = "kubernetes.io/container/cpu/limit_utilization"
      EOT
      duration        = "180s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.95
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields = ["resource.labels.pod_name"]
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.id]
  
  alert_strategy {
    auto_close = "1800s"
  }
  
  documentation {
    content   = <<-EOT

      1. Review CPU limits
      2. Consider increasing CPU limits or removing them
      3. Check application CPU usage patterns
    EOT
    mime_type = "text/markdown"
  }
}