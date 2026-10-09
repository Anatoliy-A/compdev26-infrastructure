module "guestbook_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.3"

  name                = module.naming.names.user_assigned_identity.name_unique
  location            = var.location
  resource_group_name = local.resource_group_name
  enable_telemetry    = false

  # The issuer changes when AKS is recreated, which replaces this credential on the next apply.
  federated_identity_credentials = {
    guestbook = {
      name     = "aks-${var.guestbook_namespace}-${var.guestbook_service_account}"
      audience = ["api://AzureADTokenExchange"]
      issuer   = local.aks_oidc_issuer_url
      subject  = "system:serviceaccount:${var.guestbook_namespace}:${var.guestbook_service_account}"
    }
  }
}

# The GUID is the fixed ID of the built-in "Cosmos DB Built-in Data Contributor" role.
data "azurerm_cosmosdb_sql_role_definition" "data_contributor" {
  role_definition_id  = "00000000-0000-0000-0000-000000000002"
  resource_group_name = local.resource_group_name
  account_name        = module.cosmos.name

  depends_on = [module.cosmos]
}

# The module's role_assignments creates ARM RBAC, not Cosmos data-plane roles, so this stays a resource.
resource "azurerm_cosmosdb_sql_role_assignment" "guestbook" {
  resource_group_name = local.resource_group_name
  account_name        = module.cosmos.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.data_contributor.id
  principal_id        = module.guestbook_identity.principal_id
  scope               = "${module.cosmos.resource_id}/dbs/${var.cosmos_database_name}/colls/${var.cosmos_container_name}"

  depends_on = [module.cosmos]
}
