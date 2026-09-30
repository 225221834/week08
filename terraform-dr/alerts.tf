# =============================================================================
# Phase 4 – Automated failover triggers
# Azure Monitor + Service Health alerts → Action Group → Automation Runbook
# =============================================================================

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# 1. Metric alert – Primary PostgreSQL server is unavailable / degraded
# -----------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "postgres_primary_unavailable" {
  name                = "${var.project_name}-postgres-primary-unavailable"
  resource_group_name = module.primary.resource_group_name
  scopes              = [azurerm_postgresql_flexible_server.primary.id]
  description         = "Fires when the primary PostgreSQL Flexible Server is unavailable or severely degraded. Triggers DR failover runbook."
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "is_db_alive"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.dr_alerts.id
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "DR-Failover"
  })
}

# -----------------------------------------------------------------------------
# 2. Service Health alert – Australia East regional issues
# -----------------------------------------------------------------------------
resource "azurerm_monitor_activity_log_alert" "service_health_australia_east" {
  name                = "${var.project_name}-servicehealth-aue"
  resource_group_name = module.primary.resource_group_name
  location            = "global"
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Fires on Service Health events (Incident / Maintenance) affecting Australia East."
  enabled             = true

  criteria {
    category = "ServiceHealth"

    service_health {
      events    = ["Incident", "Maintenance"]
      locations = ["Australia East"]
      services  = [
        "Azure Database for PostgreSQL",
        "Azure Kubernetes Service (AKS)", 
        "Azure Front Door"
      ]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.dr_alerts.id
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Purpose     = "DR-Failover"
  })
}

# -----------------------------------------------------------------------------
# 3. Webhook so the Action Group can start the Automation Runbook
# -----------------------------------------------------------------------------
resource "azurerm_automation_webhook" "failover" {
  name                    = "failover-webhook"
  resource_group_name     = module.primary.resource_group_name
  automation_account_name = azurerm_automation_account.dr.name
  expiry_time             = timeadd(timestamp(), "8760h") # 1 year
  enabled                 = true
  runbook_name            = azurerm_automation_runbook.failover.name
}

# -----------------------------------------------------------------------------
# 4. Enhanced Action Group that also starts the runbook
# Point the metric / service-health alerts at this group when you want
# fully automatic promote. For safety the alerts currently still point at
# the email-only group; switch the action_group_id after testing.
# -----------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "dr_alerts_with_runbook" {
  name                = "${var.project_name}-dr-alerts-runbook"
  resource_group_name = module.primary.resource_group_name
  short_name          = "drrunbook"

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }

  automation_runbook_receiver {
    name                    = "trigger-failover-runbook"
    automation_account_id   = azurerm_automation_account.dr.id
    runbook_name            = azurerm_automation_runbook.failover.name
    webhook_resource_id     = azurerm_automation_webhook.failover.id
    is_global_runbook       = false
    service_uri             = azurerm_automation_webhook.failover.uri
    use_common_alert_schema = true
  }
}
