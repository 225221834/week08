output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "primary_resource_group" {
  value = module.primary.resource_group_name
}

output "primary_aks_cluster_name" {
  value = module.primary.aks_cluster_name
}

output "primary_aks_get_credentials" {
  value = module.primary.aks_get_credentials_command
}

output "primary_storage_connection_string" {
  value     = module.primary.storage_connection_string
  sensitive = true
}

output "secondary_resource_group" {
  value = module.secondary.resource_group_name
}

output "secondary_aks_cluster_name" {
  value = module.secondary.aks_cluster_name
}

output "secondary_aks_get_credentials" {
  value = module.secondary.aks_get_credentials_command
}

output "secondary_storage_connection_string" {
  value     = module.secondary.storage_connection_string
  sensitive = true
}

output "github_variables_to_set" {
  description = "Copy these values into GitHub Repository Variables"
  value = {
    ACR_NAME                     = azurerm_container_registry.acr.name
    ACR_LOGIN_SERVER             = azurerm_container_registry.acr.login_server
    AKS_PRIMARY_RESOURCE_GROUP   = module.primary.resource_group_name
    AKS_PRIMARY_CLUSTER_NAME     = module.primary.aks_cluster_name
    AKS_SECONDARY_RESOURCE_GROUP = module.secondary.resource_group_name
    AKS_SECONDARY_CLUSTER_NAME   = module.secondary.aks_cluster_name
  }
}
