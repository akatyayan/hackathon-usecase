resource "google_monitoring_dashboard" "cpu_memory_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.environment} - CPU & Memory Monitoring"
    
    mosaicLayout = {
      columns = 12
      
      tiles = [
        # ============================================
        # ROW 1: CPU Metrics
        # ============================================
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod CPU Usage (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.pod_name"]
                    }
                  }
                }
                plotType   = "LINE"
                targetAxis = "Y1"
              }]
              yAxis = {
                label = "CPU Cores"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Node CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_node\" metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.node_name"]
                    }
                  }
                }
                plotType   = "LINE"
                targetAxis = "Y1"
              }]
              yAxis = {
                label = "Utilization"
                scale = "LINEAR"
              }
              thresholds = [{
                value = 0.8
                color = "YELLOW"
                direction = "ABOVE"
              }, {
                value = 0.9
                color = "RED"
                direction = "ABOVE"
              }]
            }
          }
        },
        
        # ============================================
        # ROW 2: Memory Metrics
        # ============================================
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Pod Memory Usage (MB)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/memory/used_bytes\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.pod_name"]
                    }
                  }
                }
                plotType   = "LINE"
                targetAxis = "Y1"
              }]
              yAxis = {
                label = "Memory (Bytes)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Node Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_node\" metric.type=\"kubernetes.io/node/memory/allocatable_utilization\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.node_name"]
                    }
                  }
                }
                plotType   = "LINE"
                targetAxis = "Y1"
              }]
              yAxis = {
                label = "Utilization"
                scale = "LINEAR"
              }
              thresholds = [{
                value = 0.85
                color = "YELLOW"
                direction = "ABOVE"
              }, {
                value = 0.95
                color = "RED"
                direction = "ABOVE"
              }]
            }
          }
        },
        
        # ============================================
        # ROW 3: Resource Requests vs Usage
        # ============================================
        {
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "CPU: Requests vs Usage"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/cpu/request_cores\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.pod_name"]
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Request - ${resource.pod_name}"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.pod_name"]
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Usage - ${resource.pod_name}"
                }
              ]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Memory: Requests vs Usage"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/memory/request_bytes\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.pod_name"]
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Request - ${resource.pod_name}"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" metric.type=\"kubernetes.io/container/memory/used_bytes\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_MEAN"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.pod_name"]
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Usage - ${resource.pod_name}"
                }
              ]
            }
          }
        },
        
        # ============================================
        # ROW 4: Per-Service Breakdown
        # ============================================
        {
          yPos   = 12
          width  = 6
          height = 4
          widget = {
            title = "Patient Service - CPU & Memory"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" resource.labels.container_name=\"patient-service\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "CPU Usage"
                  targetAxis = "Y1"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"k8s_container\" resource.labels.namespace_name=\"healthcare-app\" resource.labels.container_name=\"patient-service\" metric.type=\"kubernetes.io/container/memory/used_bytes\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                  legendTemplate = "Memory Usage"
                  targetAxis = "Y2"
                }
              ]
              y2Axis = {
                label = "Memory (Bytes)"
              }
            }
          }
        },
        {
          xPos   = 6
          yPos   = 12
          width  = 6
          height = 4
          widget =