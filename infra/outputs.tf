output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "vnet_id" {
  value = module.vnet.resource_id
}

output "aks_id" {
  value = module.aks.resource_id
}

output "aks_name" {
  value = module.aks.name
}

output "aks_fqdn" {
  value = module.aks.fqdn
}

output "aks_cluster_ca_certificate" {
  value     = module.aks.cluster_ca_certificate
  sensitive = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer trusted by federated credentials for AKS Workload Identity."
  value       = module.aks.oidc_issuer_profile_issuer_url
}

output "aks_node_vm_size" {
  value = var.aks_node_vm_size
}

output "aks_subnet_cidr" {
  value = module.ip_addresses.address_prefixes["aks"]
}
