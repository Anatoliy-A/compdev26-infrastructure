# Argo CD reconciles application objects from the compdev26-gitops repository.
# Dex, Notifications and the ApplicationSet controller are disabled to fit the two small
# nodes; the UI is not exposed and is reached with kubectl port-forward.
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.10.1"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  values = [yamlencode({
    dex           = { enabled = false }
    notifications = { enabled = false }

    # The chart has no enabled toggle for this controller.
    applicationSet = { replicas = 0 }

    controller = {
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    server = {
      resources = {
        requests = { cpu = "30m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }

    repoServer = {
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "300m", memory = "512Mi" }
      }
    }

    redis = {
      resources = {
        requests = { cpu = "20m", memory = "32Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }
    }
  })]
}
