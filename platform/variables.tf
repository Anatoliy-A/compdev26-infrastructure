variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
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

variable "acme_email" {
  description = "Contact email registered with Let's Encrypt for ACME account notifications."
  type        = string
}

variable "lab_hostname" {
  description = "Public DNS name served by the shared Gateway and covered by its Let's Encrypt certificate."
  type        = string
}
