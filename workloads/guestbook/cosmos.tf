# Free-tier, Entra-only Cosmos DB account (the free tier is limited to one account per subscription).
module "cosmos" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "0.11.0"

  name                = module.naming.names.database_account_cosmos_db_for_no_sql_account.name_unique
  location            = var.cosmos_location
  resource_group_name = local.resource_group_name
  enable_telemetry    = false

  free_tier_enabled             = true
  local_authentication_disabled = true
  public_network_access_enabled = true
  automatic_failover_enabled    = false

  # Module default is billed Continuous30Days backup.
  backup = {
    type = "Periodic"
  }

  consistency_policy = {
    consistency_level = "Session"
  }

  # Single region without zone redundancy keeps the account inside the free tier.
  geo_locations = [{
    location          = var.cosmos_location
    failover_priority = 0
    zone_redundant    = false
  }]

  # Shared database throughput stays within the free 1,000 RU/s allowance.
  sql_databases = {
    guestbook = {
      name       = var.cosmos_database_name
      throughput = var.cosmos_database_throughput

      containers = {
        entries = {
          name                = var.cosmos_container_name
          partition_key_paths = ["/guestbookId"]
        }
      }
    }
  }
}
