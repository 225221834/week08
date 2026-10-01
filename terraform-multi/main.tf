provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -------------------------------------------------
# Shared Premium ACR with geo-replication
# -------------------------------------------------
resource "azurerm_resource_group" "shared" {
  name     = "rg-${var.project_name}-shared"
  location = "Australia East"
  tags     = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  sku                 = "Premium"
  admin_enabled       = false          # use managed identity / AcrPull instead

  georeplications {
    location                = "Australia Southeast"
    zone_redundancy_enabled = false
  }

  tags = var.tags
}

# -------------------------------------------------
# Primary region – Australia East
# -------------------------------------------------
module "primary" {
  source = "./modules/region"

  location             = "Australia East"
  project_name         = var.project_name
  region_short         = "aue"
  resource_group_name  = "rg-${var.project_name}-aue"
  aks_cluster_name     = "aks-${var.project_name}-aue"
  aks_dns_prefix       = "${var.project_name}-aue"
  storage_account_name = "st${var.project_name}aue${random_string.suffix.result}"
  node_count           = var.node_count
  node_vm_size         = var.node_vm_size
  kubernetes_version   = var.kubernetes_version
  replication_type     = "GRS"
  tags                 = merge(var.tags, { Region = "Australia East", Role = "Primary" })
}

# -------------------------------------------------
# Secondary region – Australia Southeast
# -------------------------------------------------
module "secondary" {
  source = "./modules/region"

  location             = "Australia Southeast"
  project_name         = var.project_name
  region_short         = "ause"
  resource_group_name  = "rg-${var.project_name}-ause"
  aks_cluster_name     = "aks-${var.project_name}-ause"
  aks_dns_prefix       = "${var.project_name}-ause"
  storage_account_name = "st${var.project_name}ause${random_string.suffix.result}"
  node_count           = var.node_count
  node_vm_size         = var.node_vm_size
  kubernetes_version   = var.kubernetes_version
  replication_type     = "LRS"
  tags                 = merge(var.tags, { Region = "Australia Southeast", Role = "Secondary" })
}

# -------------------------------------------------
# Grant both AKS clusters permission to pull from the shared ACR
# -------------------------------------------------
resource "azurerm_role_assignment" "primary_acr_pull" {
  principal_id                     = module.primary.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "secondary_acr_pull" {
  principal_id                     = module.secondary.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
