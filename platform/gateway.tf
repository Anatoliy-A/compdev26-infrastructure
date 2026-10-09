resource "kubernetes_manifest" "shared_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "shared-gateway"
      namespace = kubernetes_namespace_v1.ingress_system.metadata[0].name
    }
    spec = {
      gatewayClassName = "approuting-istio"
      listeners = [
        {
          name     = "http-lab-devoops-work"
          port     = 80
          protocol = "HTTP"
          hostname = var.lab_hostname
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  "shared-gateway-access" = "true"
                }
              }
            }
          }
        },
        {
          name     = "https-lab-devoops-work"
          port     = 443
          protocol = "HTTPS"
          hostname = var.lab_hostname
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "lab-devoops-work-tls"
            }]
          }
          allowedRoutes = {
            namespaces = {
              from = "Selector"
              selector = {
                matchLabels = {
                  "shared-gateway-access" = "true"
                }
              }
            }
          }
        }
      ]
    }
  }
}

resource "kubectl_manifest" "lab_devoops_work_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "lab-devoops-work-tls"
      namespace = kubernetes_namespace_v1.ingress_system.metadata[0].name
    }
    spec = {
      secretName = "lab-devoops-work-tls"
      dnsNames   = [var.lab_hostname]
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
    }
  })

  depends_on = [kubectl_manifest.cluster_issuer_prod]
}

resource "kubernetes_manifest" "lab_devoops_work_http_redirect" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "lab-devoops-work-http-redirect"
      namespace = kubernetes_namespace_v1.ingress_system.metadata[0].name
    }
    spec = {
      parentRefs = [{
        name        = "shared-gateway"
        sectionName = "http-lab-devoops-work"
      }]
      hostnames = [var.lab_hostname]
      rules = [{
        filters = [{
          type = "RequestRedirect"
          requestRedirect = {
            scheme     = "https"
            statusCode = 301
          }
        }]
      }]
    }
  }
}
