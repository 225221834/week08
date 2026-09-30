# =============================================================================
# Phase 2 – Azure Database for PostgreSQL Flexible Server
# Primary (Australia East) + Cross-region Read Replica (Australia Southeast)
# + Virtual Endpoints for seamless application connection strings
# =============================================================================

# -----------------------------------------------------------------------------
# Primary PostgreSQL Flexible Server (Australia East)
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "primary" {
  name                   = var.postgres_primary_name
  resource_group_name    = module.primary.resource_group_name
  location               = module.primary.location
  version                = var.postgres_version
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password

  sku_name   = var.postgres_sku_name
  storage_mb = var.postgres_storage_mb

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true

  # Zone-redundant HA is supported in Australia East
  high_availability {
    mode = "ZoneRedundant"
  }

  # Public access for simplicity in this lab (lock down with firewall rules / private endpoints in production)
  public_network_access_enabled = true

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = "primary"
  })

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
    ]
  }
}

# Allow Azure services + (optionally) your own IP – tighten later
resource "azurerm_postgresql_flexible_server_firewall_rule" "primary_allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.primary.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Cross-region Read Replica (Australia Southeast)
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "replica" {
  name                = var.postgres_replica_name
  resource_group_name = module.secondary.resource_group_name
  location            = module.secondary.location

  # Create as a replica of the primary
  create_mode      = "Replica"
  source_server_id = azurerm_postgresql_flexible_server.primary.id

  # SKU / storage must match (or exceed) primary for promote-to-primary to work cleanly
  sku_name   = var.postgres_sku_name
  storage_mb = var.postgres_storage_mb

  public_network_access_enabled = true

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = "secondary"
  })

  depends_on = [
    azurerm_postgresql_flexible_server.primary
  ]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "replica_allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.replica.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Virtual Endpoint (ReadWrite) – applications should use this
# Currently azurerm only supports type = "ReadWrite"
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_virtual_endpoint" "writer" {
  name              = "${var.project_name}-writer"
  source_server_id  = azurerm_postgresql_flexible_server.primary.id
  replica_server_id = azurerm_postgresql_flexible_server.replica.id
  type              = "ReadWrite"
}

# -----------------------------------------------------------------------------
# Application databases (microservices)
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "user_db" {
  name      = "userdb"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "student_db" {
  name      = "studentdb"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "lecturer_db" {
  name      = "lecturerdb"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "course_db" {
  name      = "coursedb"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_database" "enrollment_db" {
  name      = "enrollmentdb"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}