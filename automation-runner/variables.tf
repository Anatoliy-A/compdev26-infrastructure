variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID that owns the subscription."
  type        = string
}

variable "infra_state_key" {
  description = "Remote state key containing the shared infrastructure outputs."
  type        = string
}

variable "state_resource_group_name" {
  description = "Resource group containing the Terraform state storage account."
  type        = string
}

variable "state_storage_account_name" {
  description = "Terraform state storage account name."
  type        = string
}

variable "location" {
  description = "Azure region for the runner VM."
  type        = string
}

variable "runner_name" {
  description = "Short name used for runner resource naming."
  type        = string
}

variable "runner_vm_size" {
  description = "Azure VM size for the self-hosted runner."
  type        = string
}

variable "runner_ssh_public_key" {
  description = "SSH public key used for administrator access to the runner VM."
  type        = string

  validation {
    condition     = length(trimspace(var.runner_ssh_public_key)) > 40 && !strcontains(var.runner_ssh_public_key, "PRIVATE")
    error_message = "runner_ssh_public_key must be a non-empty public SSH key and must not contain private key material."
  }
}

variable "runner_shutdown_time" {
  description = "Daily auto-shutdown time in HHmm format."
  type        = string

  validation {
    condition     = can(regex("^[0-2][0-9][0-5][0-9]$", var.runner_shutdown_time))
    error_message = "runner_shutdown_time must use HHmm format, for example 1700."
  }
}

variable "runner_shutdown_timezone" {
  description = "Azure Windows time zone ID used by the VM auto-shutdown schedule."
  type        = string
}
