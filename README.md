# compdev26-infrastructure

Terraform for a low-cost Azure Kubernetes Service (AKS) learning lab: a public AKS cluster with Gateway API ingress, automatic TLS, Argo CD, and the Azure resources for a sample guestbook app.

It is one of three repositories:

| Repository | Purpose |
| --- | --- |
| `compdev26-infrastructure` (this one) | Azure resources and shared cluster services |
| `compdev26-gitops` | Kubernetes manifests for the app, reconciled by Argo CD |
| `compdev26-guestbook` | The Go app, its tests, and the image build |

Terraform here must not declare objects that Argo CD manages, and the app repositories must not contain Terraform.

## Layout

| Folder | What it creates | State key |
| --- | --- | --- |
| `infra/` | Virtual network, AKS (Free tier, Azure CNI Overlay with Cilium, OIDC issuer and Workload Identity), managed identities, role assignments, scheduled stop | `infra.tfstate` |
| `platform/` | Namespaces, cert-manager with Let's Encrypt, the shared Gateway and TLS certificate, Argo CD | `platform.tfstate` |
| `workloads/guestbook/` | Cosmos DB (free tier), the guestbook managed identity with its federated credential, Cosmos data-plane role | `guestbook.tfstate` |
| `scripts/` | One-time helper that creates the remote-state storage account | |

Apply the roots in this order: `infra`, `platform`, `workloads/guestbook`. Each later root reads the earlier state.

## Prerequisites

- Terraform 1.9 or later (below 2.0)
- Azure CLI, signed in to the target tenant (`az login`)
- `kubelogin`, for the `platform` root
- An existing resource group and permission to create resources and role assignments in it

## Configuration

Private values are not committed. In each root, copy the example files and fill in your own values:

```powershell
Copy-Item backend.azurerm.tfbackend.example backend.azurerm.tfbackend
Copy-Item terraform.auto.tfvars.example terraform.auto.tfvars
```

`backend.azurerm.tfbackend` and `terraform.auto.tfvars` are git-ignored. `terraform.tfvars` holds the non-sensitive shared values and is committed. Variables have no defaults, so every value must be set.

## Remote state

State lives in an Azure Storage account, accessed with Microsoft Entra ID (no storage keys). To create it once:

```powershell
$env:SUBSCRIPTION_ID = "<subscription-id>"
$env:RESOURCE_GROUP  = "<existing-resource-group>"
$env:STORAGE_ACCOUNT = "<globally-unique-storage-account-name>"
bash scripts/tfstate-infra.sh
```

## Usage

From each root, in order:

```powershell
terraform init '-backend-config=backend.azurerm.tfbackend'
terraform plan -out=tfplan
terraform apply tfplan
```

Quote the `-backend-config` argument in Windows PowerShell 5.1, which otherwise splits it at the dots. Review every plan before applying, and delete the plan file afterwards.

The `platform` root talks to the cluster, so AKS must be running. The lab stops the cluster on a schedule to save cost; start it first if it is stopped.

## Cost

The lab is designed to stay at or near the cost of the node VMs only: the AKS control plane is on the Free tier, Cosmos DB uses the lifetime free tier, and images are published to GitHub Container Registry. Nothing paid, such as a container registry, private endpoints, or extra node pools, should be added without a deliberate decision.

## Conventions

- No secrets, keys, or connection strings in the repository; Azure access uses Workload Identity and Entra ID.
- No variable defaults, and pinned module and provider versions.
- Changes go through pull requests on a protected `main` branch.
