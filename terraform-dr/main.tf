# =============================================================================
# Week 08 Multi-Region DR – Phase 1 Foundation
# Primary: Australia East (Active)
# Secondary: Australia Southeast (DR)
# =============================================================================

# -----------------------------------------------------------------------------
# Primary Region Module
# -----------------------------------------------------------------------------
module "primary" {
  source = "./modules/region"

  resource_group_name  = var.primary_rg_name
  location             = var.primary_location
  region_role          = "primary"
  environment          = var.environment
  tags                 = var.tags

  storage_account_name = var.primary_storage_name
  aks_cluster_name     = var.primary_aks_name
  aks_dns_prefix       = "${var.aks_dns_prefix}aue"
  aks_node_count       = var.aks_node_count_primary
  aks_node_vm_size     = var.aks_node_vm_size
  kubernetes_version   = var.kubernetes_version
}

# -----------------------------------------------------------------------------
# Secondary Region Module
# -----------------------------------------------------------------------------
module "secondary" {
  source = "./modules/region"

  resource_group_name  = var.secondary_rg_name
  location             = var.secondary_location
  region_role          = "secondary"
  environment          = var.environment
  tags                 = var.tags

  storage_account_name = var.secondary_storage_name
  aks_cluster_name     = var.secondary_aks_name
  aks_dns_prefix       = "${var.aks_dns_prefix}aus"
  aks_node_count       = var.aks_node_count_secondary
  aks_node_vm_size     = var.aks_node_vm_size
  kubernetes_version   = var.kubernetes_version
}

# -----------------------------------------------------------------------------
# Azure Container Registry (single global ACR with geo-replication)
# Placed in primary region; geo-replicates to secondary
# -----------------------------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = module.primary.resource_group_name
  location            = module.primary.location
  sku                 = "Premium" # Premium required for geo-replication
  admin_enabled       = true

  # Geo-replicate to Australia Southeast
  georeplications {
    location                = var.secondary_location
    zone_redundancy_enabled = false
    tags                    = var.tags
  }

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = "global"
  })
}

# Grant both AKS clusters AcrPull
resource "azurerm_role_assignment" "acr_pull_primary" {
  principal_id                     = module.primary.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pull_secondary" {
  principal_id                     = module.secondary.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# Random suffix helper (optional – for unique names if needed)
# -----------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}