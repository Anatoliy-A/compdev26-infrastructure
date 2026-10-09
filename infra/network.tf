module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.22.2"

  name             = module.naming.names.virtual_network.name_unique
  location         = var.location
  parent_id        = data.azurerm_resource_group.this.id
  address_space    = ["10.0.0.0/16"]
  enable_telemetry = false

  subnets = {
    aks = {
      name             = module.naming.names.virtual_network_subnet.name_unique
      address_prefixes = [module.ip_addresses.address_prefixes["aks"]]
    }
  }

  role_assignments = {
    aks_network_contributor = {
      role_definition_id_or_name = module.role_definitions.role_definition_rolename_to_resource_id["Network Contributor"]
      principal_id               = azurerm_user_assigned_identity.aks.principal_id
      principal_type             = "ServicePrincipal"
    }
  }
}
