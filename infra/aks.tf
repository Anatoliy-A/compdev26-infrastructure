module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "~> 0.8.3"

  name                   = module.naming.names.container_service_managed_cluster.name_unique
  location               = var.location
  parent_id              = data.azurerm_resource_group.this.id
  kubernetes_version     = var.kubernetes_version
  enable_telemetry       = false
  enable_rbac            = true
  disable_local_accounts = true

  aad_profile = {
    managed           = true
    enable_azure_rbac = true
  }

  sku = {
    name = "Base"
    tier = "Free"
  }

  auto_upgrade_profile = {
    upgrade_channel         = "patch"
    node_os_upgrade_channel = "NodeImage"
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.aks.id]
  }

  api_server_access_profile = {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  default_agent_pool = {
    name                = "systempool"
    count_of            = 2
    enable_auto_scaling = false
    mode                = "System"
    os_sku              = "AzureLinux"
    os_type             = "Linux"
    os_disk_type        = "Managed"
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = module.vnet.subnets["aks"].resource_id
  }

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
  }

  ingress_profile = {
    gateway_api = {
      installation = "Standard"
    }
    web_app_routing = {
      enabled = true
      gateway_api_implementations = {
        app_routing_istio = {
          mode = "Enabled"
        }
      }
      nginx = {
        default_ingress_controller_type = "None"
      }
    }
  }

  depends_on = [module.vnet]
}
