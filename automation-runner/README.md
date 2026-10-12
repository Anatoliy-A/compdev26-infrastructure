# GitHub Actions Runner VM

This root provisions one small Linux VM for trusted GitHub Actions Terraform plan/apply jobs. It uses the AVM virtual-machine module, a static public IP, a NIC-level NSG with no inbound rules, system-assigned identity, and a daily 17:00 `W. Europe Standard Time` shutdown schedule.

The VM is intentionally separate from the shared Terraform roots so it has independent state and can be destroyed without touching AKS, Cosmos DB or platform state.

Apply `infra/` first so this root can read the existing AKS subnet ID from `infra.tfstate`.

Copy the ignored files before initialization:

```powershell
Copy-Item backend.azurerm.tfbackend.example backend.azurerm.tfbackend
Copy-Item terraform.auto.tfvars.example terraform.auto.tfvars
```

Put an SSH public key in `terraform.auto.tfvars`. Never put a private key, GitHub runner registration token or personal access token in Terraform or state.

```powershell
terraform init '-backend-config=backend.azurerm.tfbackend'
terraform plan -out=tfplan
terraform apply tfplan
```

The VM is stopped at 17:00 and must be started before jobs can use it. Runner installation and registration are intentionally manual. Register it in the `azure-lab` GitHub runner group with label `azure-lab`, then install the GitHub runner service.
