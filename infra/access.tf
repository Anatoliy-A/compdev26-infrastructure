data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = module.aks.resource_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  scope                = module.aks.resource_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

