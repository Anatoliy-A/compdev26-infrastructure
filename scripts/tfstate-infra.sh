#!/bin/bash

set -euo pipefail

# Creates the Terraform remote-state storage account + container for this test project.
# Usage: SUBSCRIPTION_ID=<id> RESOURCE_GROUP=<existing-rg> STORAGE_ACCOUNT=<globally-unique-name> tfstate-infra.sh
#
# Prerequisites: logged in with 'az login' on the target tenant.

: "${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID}"
: "${RESOURCE_GROUP:?Set RESOURCE_GROUP}"
: "${STORAGE_ACCOUNT:?Set STORAGE_ACCOUNT}"
LOCATION="westeurope"
CONTAINER_NAME="terraform-state"

echo "Switching to subscription ${SUBSCRIPTION_ID}..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "Registering resource provider: Microsoft.Storage..."
STATE=$(az provider show --namespace Microsoft.Storage --query registrationState -o tsv | tr -d '\r')
if [ "$STATE" != "Registered" ]; then
  az provider register --namespace Microsoft.Storage --wait
fi

# Resource group is assumed to already exist.

echo "Creating Storage Account: ${STORAGE_ACCOUNT}..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-shared-key-access false \
  --https-only true \
  --subscription "$SUBSCRIPTION_ID" \
  --tags "project=compdev2026" "managed_by=script"

echo "Enabling blob/container soft delete (7-day retention)..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --subscription "$SUBSCRIPTION_ID" \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 7

echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --subscription "$SUBSCRIPTION_ID" \
  --enable-versioning true

echo "Creating container: ${CONTAINER_NAME}..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --public-access off

echo "Granting Storage Blob Data Contributor role to the current user..."
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv | tr -d '\r')
ROLE_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}/blobServices/default/containers/${CONTAINER_NAME}"
# MSYS_NO_PATHCONV/MSYS2_ARG_CONV_EXCL stop Git Bash from mangling the leading "/subscriptions/..." into a Windows path.
ROLE_ASSIGN_OUTPUT=$(MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" az role assignment create \
  --assignee-object-id "$CURRENT_USER_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$ROLE_SCOPE" \
  --only-show-errors \
  2>&1 1>/dev/null) || true

if [ -n "$ROLE_ASSIGN_OUTPUT" ] && ! echo "$ROLE_ASSIGN_OUTPUT" | grep -qi "already exists"; then
  echo "$ROLE_ASSIGN_OUTPUT"
  exit 1
fi
echo "Storage Blob Data Contributor role assigned (or already exists)."

# RBAC propagation can take up to ~60s, verify before locking down the network.
echo "Waiting for role assignment to propagate..."
MAX_ATTEMPTS=12
ATTEMPT=0
until az storage blob list \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER_NAME" \
  --auth-mode login \
  --output none 2>/dev/null; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "Error: Blob access did not become available after $((MAX_ATTEMPTS * 10))s. Check role assignment."
    exit 1
  fi
  echo "  Not yet accessible, retrying in 10s... (${ATTEMPT}/${MAX_ATTEMPTS})"
  sleep 10
done
echo "Blob access confirmed."

echo "Detecting current public IP for storage account firewall allow list..."
CURRENT_PUBLIC_IP=$(curl -s https://api.ipify.org | tr -d '\r')
if [ -z "$CURRENT_PUBLIC_IP" ]; then
  echo "Error: Failed to determine current public IP."
  exit 1
fi

echo "Allowing current public IP ${CURRENT_PUBLIC_IP} and locking down the firewall..."
az storage account network-rule add \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --subscription "$SUBSCRIPTION_ID" \
  --ip-address "$CURRENT_PUBLIC_IP"

az storage account update \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --subscription "$SUBSCRIPTION_ID" \
  --default-action Deny \
  --bypass AzureServices

cat <<EOF

Done. Backend values for each root's backend.azurerm.tfbackend (key is per root, for example infra.tfstate):
  resource_group_name  = "${RESOURCE_GROUP}"
  storage_account_name = "${STORAGE_ACCOUNT}"
  container_name       = "${CONTAINER_NAME}"
  use_azuread_auth     = true

Note: if your public IP changes later, re-run:
  az storage account network-rule add --account-name ${STORAGE_ACCOUNT} --resource-group ${RESOURCE_GROUP} --ip-address <new-ip>
EOF
