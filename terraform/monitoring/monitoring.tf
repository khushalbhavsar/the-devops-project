terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

# Prometheus Configuration
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "51.2.0"

  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
        }
      }
      grafana = {
        enabled = true
        adminPassword = "admin123"
        persistence = {
          enabled = true
          size    = "10Gi"
        }
        service = {
          type = "LoadBalancer"
        }
        dashboardProviders = {
          dashboardproviders = {
            apiVersion = 1
            providers = [{
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }]
          }
        }
        dashboards = {
          default = {
            kubernetes-cluster-monitoring = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            kubernetes-pod-monitoring = {
              gnetId     = 6417
              revision   = 1
              datasource = "Prometheus"
            }
            flask-app-monitoring = {
              json = file("${path.module}/dashboards/flask-app-dashboard.json")
            }
          }
        }
      }
      alertmanager = {
        enabled = true
        config = {
          global = {
            smtp_smarthost = "localhost:587"
          }
          route = {
            group_by        = ["alertname"]
            group_wait      = "10s"
            group_interval  = "10s"
            repeat_interval = "1h"
            receiver        = "web.hook"
          }
          receivers = [{
            name = "web.hook"
            webhook_configs = [{
              url = "http://127.0.0.1:5001/"
            }]
          }]
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Service Monitor for Flask App
resource "kubernetes_manifest" "flask_app_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "flask-app-monitor"
      namespace = "monitoring"
      labels = {
        app = "flask-app"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "flask-app"
        }
      }
      endpoints = [{
        port     = "http"
        path     = "/metrics"
        interval = "30s"
      }]
      namespaceSelector = {
        matchNames = ["default"]
      }
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}