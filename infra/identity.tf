resource "azurerm_user_assigned_identity" "aks" {
  name                = module.naming.names.user_assigned_identity.name_unique
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
}
