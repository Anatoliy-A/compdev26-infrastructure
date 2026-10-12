output "runner_resource_id" {
  description = "Resource ID of the self-hosted runner VM."
  value       = module.runner.resource_id
}

output "runner_public_ips" {
  description = "Public IP object map for the runner; use the address to allow AKS and storage access."
  value       = module.runner.public_ips
}

output "runner_system_assigned_identity_principal_id" {
  description = "System-assigned identity principal ID for optional Azure access from the runner."
  value       = module.runner.system_assigned_mi_principal_id
}
