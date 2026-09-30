# -----------------------------------------------------------------------------
# Reusable region module – deploys RG + AKS + Storage for one region
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = var.region_role # "primary" or "secondary"
  })
}

# -----------------------------------------------------------------------------
# Storage Account (LRS in secondary is fine for cost; can upgrade to GRS later)
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = var.region_role == "primary" ? "GRS" : "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = var.region_role
  })
}

resource "azurerm_storage_container" "student_profile_photo" {
  name                  = "student-profile-photo"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "lecturer_profile_photo" {
  name                  = "lecturer-profile-photo"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.aks_dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    # Enable zones only where supported (Australia East has zones)
    zones               = var.location == "Australia East" ? ["1", "2", "3"] : null
    type                = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = var.region_role
  })
}

# Outputs for parent module
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "aks_kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_primary_connection_string" {
  value     = azurerm_storage_account.this.primary_connection_string
  sensitive = true
}

output "student_profile_container" {
  value = azurerm_storage_container.student_profile_photo.name
}

output "lecturer_profile_container" {
  value = azurerm_storage_container.lecturer_profile_photo.name
}