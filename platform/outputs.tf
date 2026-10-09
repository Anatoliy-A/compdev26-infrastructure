output "gateway_name" {
  value = kubernetes_manifest.shared_gateway.object.metadata.name
}
