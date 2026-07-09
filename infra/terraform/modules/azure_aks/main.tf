# ==============================================================================
# COST WARNING: applying this module creates real, billable Azure resources.
# Unlike EKS, AKS's control plane is free - you pay for:
#   - Node pool: default 2x Standard_DS2_v2 (~$140/mo combined, on-demand)
#   - Storage account: near-zero at low usage, billed per GB + transactions
# This module is standalone - it is NOT wired into any envs/*/main.tf (this
# repo's Terraform state is AWS-only). It exists to demonstrate the same
# app5-fileservice Helm chart targeting a second cloud, per the multi-cloud
# requirement - see docs/app5-multicloud-demo.md. Needs `az login` and an
# azurerm provider block (subscription_id/tenant_id) supplied by the caller.
# ==============================================================================

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-app5-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${local.name_prefix}-app5-aks"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "${local.name_prefix}-app5"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  tags = local.common_tags
}

resource "azurerm_storage_container" "app5_uploads" {
  name                  = "app5-uploads"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
