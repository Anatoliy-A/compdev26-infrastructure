variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID that owns the subscription."
  type        = string
}

variable "aks_admin_principal_id" {
  description = "Object ID of the user, group, or service principal receiving AKS access roles."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.aks_admin_principal_id))
    error_message = "aks_admin_principal_id must be a Microsoft Entra object ID GUID."
  }
}

variable "aks_admin_principal_type" {
  description = "Principal type for the AKS access role assignments."
  type        = string

  validation {
    condition     = contains(["User", "Group", "ServicePrincipal"], var.aks_admin_principal_type)
    error_message = "aks_admin_principal_type must be User, Group, or ServicePrincipal."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "workload_name" {
  description = "Short workload name used as input to the naming module."
  type        = string
}

variable "aks_node_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes minor version; patch releases are managed by the patch auto-upgrade channel."
  type        = string
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges allowed to access the public AKS API server."
  type        = list(string)
}

variable "aks_stop_schedule_start_time" {
  description = "Future RFC3339 anchor for the weekday 17:00 Europe/Berlin AKS stop schedule"
  type        = string
}

