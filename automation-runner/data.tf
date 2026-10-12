data "terraform_remote_state" "infra" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = "terraform-state"
    key                  = var.infra_state_key
    use_azuread_auth     = true
    tenant_id            = var.tenant_id
  }
}

locals {
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  runner_subnet_id    = data.terraform_remote_state.infra.outputs.runner_subnet_id
}
