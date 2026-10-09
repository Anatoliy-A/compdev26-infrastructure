# Low-cost scheduled stop for the AKS cluster on weekday evenings. Stopping the
# cluster deallocates the control plane and node VMs so neither is billed.

resource "azurerm_automation_account" "this" {
  name                = module.naming.names.automation_account.name_unique
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

# Least-privilege: management-plane control over this specific AKS cluster only,
# no access to kubeconfig or in-cluster data.
resource "azurerm_role_assignment" "automation_aks_contributor" {
  scope                = module.aks.resource_id
  role_definition_name = "Azure Kubernetes Service Contributor Role"
  principal_id         = azurerm_automation_account.this.identity[0].principal_id
}

resource "azurerm_automation_runbook" "stop_aks" {
  name                    = "Stop-AksCluster"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"

  content = <<-PWSH
    param(
      [string]$ResourceGroupName,
      [string]$ClusterName
    )

    Connect-AzAccount -Identity | Out-Null

    $subscriptionId = (Get-AzContext).Subscription.Id
    $path = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ContainerService/managedClusters/$ClusterName/stop?api-version=2024-05-01"

    Invoke-AzRestMethod -Path $path -Method POST
  PWSH
}

resource "azurerm_automation_schedule" "stop_aks_weekdays" {
  name                    = "stop-aks-weekdays-1700"
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = "Week"
  interval                = 1
  timezone                = "Europe/Berlin"
  start_time              = var.aks_stop_schedule_start_time
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  description             = "Stops the AKS cluster at 17:00 Europe/Berlin on weekdays to save cost."

  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "azurerm_automation_job_schedule" "stop_aks_weekdays" {
  resource_group_name     = data.azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  schedule_name           = azurerm_automation_schedule.stop_aks_weekdays.name
  runbook_name            = azurerm_automation_runbook.stop_aks.name

  parameters = {
    resourcegroupname = data.azurerm_resource_group.this.name
    clustername       = module.aks.name
  }
}
