# -----------------------------------------------------------------------------
# Primary Region Outputs
# -----------------------------------------------------------------------------
output "primary_resource_group_name" {
  value = module.primary.resource_group_name
}

output "primary_location" {
  value = module.primary.location
}

output "primary_aks_cluster_name" {
  value = module.primary.aks_cluster_name
}

output "primary_aks_get_credentials" {
  value = "az aks get-credentials --resource-group ${module.primary.resource_group_name} --name ${module.primary.aks_cluster_name} --overwrite-existing"
}

output "primary_storage_account_name" {
  value = module.primary.storage_account_name
}

output "primary_storage_connection_string" {
  value     = module.primary.storage_primary_connection_string
  sensitive = true
}

# -----------------------------------------------------------------------------
# Secondary Region Outputs
# -----------------------------------------------------------------------------
output "secondary_resource_group_name" {
  value = module.secondary.resource_group_name
}

output "secondary_location" {
  value = module.secondary.location
}

output "secondary_aks_cluster_name" {
  value = module.secondary.aks_cluster_name
}

output "secondary_aks_get_credentials" {
  value = "az aks get-credentials --resource-group ${module.secondary.resource_group_name} --name ${module.secondary.aks_cluster_name} --overwrite-existing"
}

output "secondary_storage_account_name" {
  value = module.secondary.storage_account_name
}

output "secondary_storage_connection_string" {
  value     = module.secondary.storage_primary_connection_string
  sensitive = true
}

# -----------------------------------------------------------------------------
# Global / Shared
# -----------------------------------------------------------------------------
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_login_command" {
  value = "az acr login --name ${azurerm_container_registry.acr.name}"
}

output "student_profile_container" {
  value = module.primary.student_profile_container
}

output "lecturer_profile_container" {
  value = module.primary.lecturer_profile_container
}
# -----------------------------------------------------------------------------
# PostgreSQL Outputs
# -----------------------------------------------------------------------------
output "postgres_primary_fqdn" {
  description = "FQDN of the primary PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.primary.fqdn
}

output "postgres_replica_fqdn" {
  description = "FQDN of the cross-region read replica"
  value       = azurerm_postgresql_flexible_server.replica.fqdn
}

output "postgres_writer_endpoint" {
  description = "Virtual endpoint (ReadWrite) – USE THIS in application connection strings"
  value       = azurerm_postgresql_flexible_server_virtual_endpoint.writer.name
}

output "postgres_connection_string_template" {
  description = "Template connection string using the writer virtual endpoint"
  value       = "postgresql://${var.postgres_admin_login}:<password>@${azurerm_postgresql_flexible_server_virtual_endpoint.writer.name}.postgres.database.azure.com:5432/<dbname>?sslmode=require"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Front Door / Automation Outputs
# -----------------------------------------------------------------------------
output "frontdoor_endpoint_hostname" {
  description = "Front Door endpoint hostname – point your custom domain / DNS here"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "frontdoor_profile_name" {
  value = azurerm_cdn_frontdoor_profile.main.name
}

output "automation_account_name" {
  value = azurerm_automation_account.dr.name
}

output "failover_runbook_name" {
  value = azurerm_automation_runbook.failover.name
}

output "action_group_name" {
  value = azurerm_monitor_action_group.dr_alerts.name
}

output "failover_webhook_uri" {
  description = "Webhook URI that can start the failover runbook (sensitive)"
  value       = azurerm_automation_webhook.failover.uri
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Alert / Automation Outputs (Phase 4)
# -----------------------------------------------------------------------------
output "metric_alert_postgres_name" {
  value = azurerm_monitor_metric_alert.postgres_primary_unavailable.name
}

output "service_health_alert_name" {
  value = azurerm_monitor_activity_log_alert.service_health_australia_east.name
}

output "action_group_with_runbook_name" {
  value = azurerm_monitor_action_group.dr_alerts_with_runbook.name
}

output "automation_webhook_name" {
  value = azurerm_automation_webhook.failover.name
}
