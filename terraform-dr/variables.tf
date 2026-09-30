# -----------------------------------------------------------------------------
# Global / Common
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Short project name used in resource naming"
  type        = string
  default     = "koalatech"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "KoalaTech Web Platform"
    ManagedBy   = "Terraform"
    Practical   = "Week08-DR"
    Environment = "Production"
  }
}

# -----------------------------------------------------------------------------
# Regions
# -----------------------------------------------------------------------------
variable "primary_location" {
  description = "Primary (Active) Azure region"
  type        = string
  default     = "Australia East"
}

variable "secondary_location" {
  description = "Secondary (DR) Azure region"
  type        = string
  default     = "Australia Southeast"
}

# -----------------------------------------------------------------------------
# Naming (must be globally unique where required)
# -----------------------------------------------------------------------------
variable "primary_rg_name" {
  description = "Resource group name for primary region"
  type        = string
  default     = "rg-koalatech-aue-prod"
}

variable "secondary_rg_name" {
  description = "Resource group name for secondary region"
  type        = string
  default     = "rg-koalatech-aus-prod"
}

variable "acr_name" {
  description = "Globally unique ACR name (alphanumeric only)"
  type        = string
  default     = "koalatechweek08acr"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.acr_name))
    error_message = "ACR name must be alphanumeric only."
  }
}

variable "primary_storage_name" {
  description = "Globally unique storage account name (primary)"
  type        = string
  default     = "koalatechauestorage"

  validation {
    condition     = length(var.primary_storage_name) >= 3 && length(var.primary_storage_name) <= 24 && can(regex("^[a-z0-9]+$", var.primary_storage_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "secondary_storage_name" {
  description = "Globally unique storage account name (secondary)"
  type        = string
  default     = "koalatechausstorage"

  validation {
    condition     = length(var.secondary_storage_name) >= 3 && length(var.secondary_storage_name) <= 24 && can(regex("^[a-z0-9]+$", var.secondary_storage_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "primary_aks_name" {
  description = "Primary AKS cluster name"
  type        = string
  default     = "aks-koalatech-aue"
}

variable "secondary_aks_name" {
  description = "Secondary AKS cluster name"
  type        = string
  default     = "aks-koalatech-aus"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for AKS clusters"
  type        = string
  default     = "koalatech"
}

# -----------------------------------------------------------------------------
# AKS sizing
# -----------------------------------------------------------------------------
variable "aks_node_count_primary" {
  description = "Node count for primary AKS (active)"
  type        = number
  default     = 3
}

variable "aks_node_count_secondary" {
  description = "Node count for secondary AKS (DR – can be smaller until failover)"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.31.2" # Use a currently supported version in both regions
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server (foundation – full config in later phase)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------
variable "postgres_primary_name" {
  description = "Name of the primary PostgreSQL Flexible Server (globally unique)"
  type        = string
  default     = "psql-koalatech-aue"
}

variable "postgres_replica_name" {
  description = "Name of the cross-region read replica"
  type        = string
  default     = "psql-koalatech-aus"
}

variable "postgres_admin_login" {
  description = "PostgreSQL administrator login"
  type        = string
  default     = "pgadmin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_sku_name" {
  description = "PostgreSQL Flexible Server SKU (must support read replicas)"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage size in MB"
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

# -----------------------------------------------------------------------------
# Front Door / Origins (Phase 3)
# After deploying the week08 workloads, put the real ingress hostnames here.
# Until then you can use temporary public IPs or leave placeholders.
# -----------------------------------------------------------------------------
variable "primary_origin_hostname" {
  description = "Hostname or public IP of the primary AKS ingress / frontend"
  type        = string
  default     = "primary-placeholder.example.com"
}

variable "secondary_origin_hostname" {
  description = "Hostname or public IP of the secondary AKS ingress / frontend"
  type        = string
  default     = "secondary-placeholder.example.com"
}

variable "alert_email" {
  description = "Email address for DR alerts"
  type        = string
  default     = "ops@example.com"
}
