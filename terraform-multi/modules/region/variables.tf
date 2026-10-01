variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "region_short" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "aks_cluster_name" {
  type = string
}

variable "aks_dns_prefix" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_vm_size" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "replication_type" {
  type = string
}

variable "tags" {
  type = map(string)
}
