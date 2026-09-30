# =============================================================================
# Phase 3 – Azure Automation Account + Failover Runbook foundation
# The runbook will promote the PostgreSQL replica and can be triggered by
# Azure Monitor alerts / Service Health.
# =============================================================================

resource "azurerm_automation_account" "dr" {
  name                = "${var.project_name}-automation-dr"
  location            = module.primary.location
  resource_group_name = module.primary.resource_group_name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = "global"
  })
}

# Grant the Automation Account permission to manage PostgreSQL and AKS
resource "azurerm_role_assignment" "automation_contributor_primary" {
  scope                = module.primary.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.dr.identity[0].principal_id
}

resource "azurerm_role_assignment" "automation_contributor_secondary" {
  scope                = module.secondary.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.dr.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# Failover Runbook (PowerShell)
# This is a starter runbook. You will refine the promote + scale logic later.
# -----------------------------------------------------------------------------
resource "azurerm_automation_runbook" "failover" {
  name                    = "PostgreSQL-Failover-to-Secondary"
  location                = azurerm_automation_account.dr.location
  resource_group_name     = azurerm_automation_account.dr.resource_group_name
  automation_account_name = azurerm_automation_account.dr.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"

  content = <<-CONTENT
param(
    [string]$PrimaryServerName = "${var.postgres_primary_name}",
    [string]$ReplicaServerName = "${var.postgres_replica_name}",
    [string]$PrimaryRg         = "${var.primary_rg_name}",
    [string]$SecondaryRg       = "${var.secondary_rg_name}"
)

Write-Output "Starting PostgreSQL failover / promote procedure..."
Write-Output "Primary : $PrimaryServerName ($PrimaryRg)"
Write-Output "Replica : $ReplicaServerName ($SecondaryRg)"

# Login with managed identity
Connect-AzAccount -Identity

# Promote the replica to primary (switchover / forced)
# For a true regional outage use --promote-option Forced
Write-Output "Promoting replica to primary..."
az postgres flexible-server replica promote `
  --resource-group $SecondaryRg `
  --name $ReplicaServerName `
  --promote-mode switchover `
  --promote-option planned `
  --yes

if ($LASTEXITCODE -ne 0) {
    Write-Error "Promote command failed. Check replication lag and server symmetry."
    exit 1
}

Write-Output "Promote completed successfully."
Write-Output "Virtual endpoint (writer) should now point to the former replica."
Write-Output "Front Door will continue to route traffic according to health probes."
CONTENT

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

# -----------------------------------------------------------------------------
# Action Group for notifications (email / webhook)
# -----------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "dr_alerts" {
  name                = "${var.project_name}-dr-alerts"
  resource_group_name = module.primary.resource_group_name
  short_name          = "dralerts"

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }
}