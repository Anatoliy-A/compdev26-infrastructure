resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

resource "kubernetes_namespace_v1" "guestbook" {
  metadata {
    name = "guestbook"
    labels = {
      "shared-gateway-access"                      = "true"
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

resource "kubernetes_namespace_v1" "ingress_system" {
  metadata {
    name = "ingress-system"
    labels = {
      "shared-gateway-access"                    = "true"
      "pod-security.kubernetes.io/audit"         = "restricted"
      "pod-security.kubernetes.io/audit-version" = "latest"
      "pod-security.kubernetes.io/warn"          = "restricted"
      "pod-security.kubernetes.io/warn-version"  = "latest"
    }
  }
}
