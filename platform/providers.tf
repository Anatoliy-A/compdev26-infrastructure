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
  aks_host = "https://${data.terraform_remote_state.infra.outputs.aks_fqdn}"

  # Well-known Microsoft Entra server app ID for AKS in Azure public cloud; fixed by
  # Microsoft, identical across all tenants/clusters.
  aks_aad_server_app_id = "6dae42f8-4368-4678-94ff-3960e28e3630"
}

provider "kubernetes" {
  host                   = local.aks_host
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.aks_cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login", "azurecli",
      "--tenant-id", var.tenant_id,
      "--server-id", local.aks_aad_server_app_id
    ]
  }
}

# cert-manager is installed via Helm; reuses the same Entra/kubelogin auth as the Kubernetes provider.
provider "helm" {
  kubernetes {
    host                   = local.aks_host
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.aks_cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--login", "azurecli",
        "--tenant-id", var.tenant_id,
        "--server-id", local.aks_aad_server_app_id
      ]
    }
  }
}

# kubectl_manifest does not validate CRD schemas at plan time, unlike kubernetes_manifest,
# so it can create cert-manager custom resources in the same apply that installs their CRDs.
provider "kubectl" {
  host                   = local.aks_host
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.aks_cluster_ca_certificate)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login", "azurecli",
      "--tenant-id", var.tenant_id,
      "--server-id", local.aks_aad_server_app_id
    ]
  }
}
