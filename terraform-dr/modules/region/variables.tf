variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "region_role" {
  description = "primary or secondary"
  type        = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "storage_account_name" {
  type = string
}

variable "aks_cluster_name" {
  type = string
}

variable "aks_dns_prefix" {
  type = string
}

variable "aks_node_count" {
  type = number
}

variable "aks_node_vm_size" {
  type = string
}

variable "kubernetes_version" {
  type = string
}