output "cosmos_endpoint" {
  description = "Cosmos DB account endpoint; an identifier, not a credential."
  value       = module.cosmos.endpoint
}

output "cosmos_database_name" {
  value = var.cosmos_database_name
}

output "cosmos_container_name" {
  value = var.cosmos_container_name
}

output "guestbook_identity_client_id" {
  description = "Client ID annotated on the guestbook ServiceAccount; an identifier, not a credential."
  value       = module.guestbook_identity.client_id
}

output "guestbook_identity_id" {
  value = module.guestbook_identity.resource_id
}

output "guestbook_federated_subject" {
  description = "ServiceAccount subject trusted by the federated credential."
  value       = "system:serviceaccount:${var.guestbook_namespace}:${var.guestbook_service_account}"
}
