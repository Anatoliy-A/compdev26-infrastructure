# cert-manager issues TLS certificates automatically via ACME (Let's Encrypt).
# Installed via Helm since the upstream install is a large multi-resource manifest
# (CRDs + controller + webhook + cainjector + RBAC).
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.16.3"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  # Lets cert-manager watch Gateway API HTTPRoute/Gateway resources for HTTP-01 solving.
  set {
    name  = "extraArgs[0]"
    value = "--enable-gateway-api"
  }
}

# Staging issuer: use first to validate the HTTP-01 flow without hitting Let's Encrypt's
# production rate limits. Staging certs are not trusted by browsers.
# kubectl_manifest (not kubernetes_manifest) because the ClusterIssuer CRD is installed
# by helm_release.cert_manager in this same apply; kubernetes_manifest would fail plan-time
# schema validation before the CRD exists.
resource "kubectl_manifest" "cluster_issuer_staging" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "letsencrypt-staging-account-key"
        }
        solvers = [{
          http01 = {
            gatewayHTTPRoute = {
              parentRefs = [{
                name      = "shared-gateway"
                namespace = kubernetes_namespace_v1.ingress_system.metadata[0].name
                kind      = "Gateway"
              }]
            }
          }
        }]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

# Production issuer: switch Certificate.spec.issuerRef to this once staging is verified working.
resource "kubectl_manifest" "cluster_issuer_prod" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_email
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [{
          http01 = {
            gatewayHTTPRoute = {
              parentRefs = [{
                name      = "shared-gateway"
                namespace = kubernetes_namespace_v1.ingress_system.metadata[0].name
                kind      = "Gateway"
              }]
            }
          }
        }]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}
