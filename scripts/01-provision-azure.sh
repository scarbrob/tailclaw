#!/usr/bin/env bash
# 01-provision-azure.sh — Create Azure VM with zero public exposure
set -euo pipefail

source "$(dirname "$0")/../config.env"

VNET_NAME="vnet-${AZURE_VM_NAME}"
SUBNET_NAME="snet-${AZURE_VM_NAME}"
NSG_NAME="nsg-${AZURE_VM_NAME}"

echo "=== Provisioning Azure Infrastructure ==="

# Resource group
echo "[1/5] Creating resource group ${AZURE_RESOURCE_GROUP} in ${AZURE_LOCATION}..."
az group create \
  --name "$AZURE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION" \
  --output none

# Virtual network
echo "[2/5] Creating VNET..."
az network vnet create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefix "10.0.0.0/16" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefix "10.0.1.0/24" \
  --output none

# Network security group — deny ALL inbound
echo "[3/5] Creating NSG (deny-all-inbound)..."
az network nsg create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$NSG_NAME" \
  --output none

az network nsg rule create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name "DenyAllInbound" \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --source-address-prefixes "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*" \
  --protocol "*" \
  --output none

# Associate NSG with subnet
echo "[4/5] Associating NSG with subnet..."
az network vnet subnet update \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --network-security-group "$NSG_NAME" \
  --output none

# Create VM — NO public IP
echo "[5/5] Creating VM ${AZURE_VM_NAME} (${AZURE_VM_SIZE}, Ubuntu 24.04, no public IP)..."
az vm create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --name "$AZURE_VM_NAME" \
  --image "Canonical:ubuntu-24_04-lts:server:latest" \
  --size "$AZURE_VM_SIZE" \
  --admin-username "$AZURE_ADMIN_USER" \
  --generate-ssh-keys \
  --public-ip-address "" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --nsg "" \
  --os-disk-size-gb 30 \
  --storage-sku StandardSSD_LRS \
  --output none

echo "=== Azure provisioning complete ==="
echo "VM has NO public IP. Use 'az vm run-command' for next steps."
