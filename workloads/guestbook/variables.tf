variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID that owns the subscription."
  type        = string
}

variable "infra_state_key" {
  description = "Remote state key containing the AKS infrastructure outputs."
  type        = string
}

variable "state_resource_group_name" {
  description = "Resource group of the Terraform state storage account that holds the infrastructure state."
  type        = string
}

variable "state_storage_account_name" {
  description = "Name of the Terraform state storage account that holds the infrastructure state."
  type        = string
}

variable "location" {
  description = "Azure region for the guestbook resources."
  type        = string
}

variable "cosmos_location" {
  description = "Azure region for the Cosmos DB account; may differ from location when the home region lacks capacity."
  type        = string
}

variable "workload_name" {
  description = "Short workload name used as input to the naming module."
  type        = string
}

variable "guestbook_namespace" {
  description = "Kubernetes namespace of the guestbook workload; part of the federated credential subject."
  type        = string
}

variable "guestbook_service_account" {
  description = "Kubernetes ServiceAccount used by the guestbook pods; part of the federated credential subject."
  type        = string
}

variable "cosmos_database_name" {
  description = "Name of the Cosmos DB SQL database."
  type        = string
}

variable "cosmos_container_name" {
  description = "Name of the Cosmos DB SQL container holding guestbook entries."
  type        = string
}

variable "cosmos_database_throughput" {
  description = "Shared manual RU/s for the database; capped at the free-tier allowance of 1,000 RU/s."
  type        = number

  validation {
    condition     = var.cosmos_database_throughput >= 400 && var.cosmos_database_throughput <= 1000 && var.cosmos_database_throughput % 100 == 0
    error_message = "cosmos_database_throughput must be between 400 and 1000 RU/s in steps of 100 to stay within the Cosmos DB free tier."
  }
}
