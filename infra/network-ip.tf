module "ip_addresses" {
  source  = "Azure/avm-utl-network-ip-addresses/azurerm"
  version = "~> 0.1.1"

  address_space = "10.0.0.0/16"
  address_prefixes = {
    aks = 24
  }
}
