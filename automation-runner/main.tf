resource "azurerm_network_security_group" "runner" {
  name                = module.naming.names.network_security_group.name_unique
  location            = var.location
  resource_group_name = local.resource_group_name

  tags = {
    purpose    = "github-actions-runner"
    managed_by = "terraform"
  }
}

module "runner" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                = module.naming.names.compute_virtual_machine.name_unique
  location            = var.location
  resource_group_name = local.resource_group_name
  zone                = null
  os_type             = "Linux"
  sku_size            = var.runner_vm_size
  enable_telemetry    = false

  account_credentials = {
    password_authentication_disabled = true
    admin_credentials = {
      username                           = "azureuser"
      ssh_keys                           = [var.runner_ssh_public_key]
      generate_admin_password_or_ssh_key = false
    }
  }

  managed_identities = {
    system_assigned = true
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interfaces = {
    runner = {
      name = module.naming.names.network_interface.name_unique

      network_security_groups = {
        runner = {
          network_security_group_resource_id = azurerm_network_security_group.runner.id
        }
      }

      ip_configurations = {
        primary = {
          name                          = "ipconfig-primary"
          private_ip_subnet_resource_id = local.runner_subnet_id
          create_public_ip_address      = true
          public_ip_address_name        = module.naming.names.public_ip_address.name_unique
          is_primary_ipconfiguration    = true
        }
      }
    }
  }

  public_ip_configuration_details = {
    allocation_method       = "Static"
    ip_version              = "IPv4"
    sku                     = "Standard"
    sku_tier                = "Regional"
    idle_timeout_in_minutes = 30
    zones                   = ["1", "2", "3"]
  }

  shutdown_schedules = {
    weekday = {
      daily_recurrence_time = var.runner_shutdown_time
      timezone              = var.runner_shutdown_timezone
      enabled               = true
      notification_settings = {
        enabled = false
      }
    }
  }

  tags = {
    purpose    = "github-actions-runner"
    managed_by = "terraform"
    schedule   = "shutdown-${var.runner_shutdown_time}"
  }
}
