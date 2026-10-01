variable "project_name" {
  description = "Short project name used in resource naming"
  type        = string
  default     = "koalatech"
}

variable "acr_name" {
  description = "Globally unique name for the Premium ACR (alphanumeric only)"
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.35"   
}

variable "node_count" {
  description = "Number of nodes in each AKS default node pool"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project   = "KoalaTech Web Platform"
    ManagedBy = "Terraform"
    Practical = "Week08-MultiRegion"
  }
}
