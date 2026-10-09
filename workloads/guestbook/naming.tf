module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "~> 0.2.0"

  suffix = [var.workload_name]
}
