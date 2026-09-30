# =============================================================================
# Phase 3 – Azure Front Door (global load balancer + automatic traffic failover)
# Priority 1 = Primary AKS (Australia East)
# Priority 2 = Secondary AKS (Australia Southeast)
# =============================================================================

# -----------------------------------------------------------------------------
# Public IPs / Ingress endpoints for AKS
# For simplicity we use the AKS cluster FQDNs / public load-balancer IPs.
# In production you would put an Application Gateway or NGINX Ingress in front
# of each cluster and point Front Door at those.
# Here we create placeholder public endpoints that you will update with the
# real ingress hostnames after deploying the week08 workloads.
# -----------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.project_name}-fd-profile"
  resource_group_name = module.primary.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = merge(var.tags, {
    Environment = var.environment
    RegionRole  = "global"
  })
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.project_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# -----------------------------------------------------------------------------
# Origin Group with priority-based failover
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "${var.project_name}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"          # change to /health once the app is deployed
    protocol            = "Http"
    interval_in_seconds = 30
    request_type        = "HEAD"
  }

  session_affinity_enabled = false
}

# Primary origin (Australia East) – Priority 1
# IMPORTANT: Replace host_name with the real ingress FQDN / public IP of the primary AKS after you deploy the week08 frontend.
resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                          = "primary-aks"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled                        = true
  host_name                      = var.primary_origin_hostname   # set in tfvars
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.primary_origin_hostname
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false   # set true once you have a real cert
}

# Secondary origin (Australia Southeast) – Priority 2
resource "azurerm_cdn_frontdoor_origin" "secondary" {
  name                          = "secondary-aks"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled                        = true
  host_name                      = var.secondary_origin_hostname  # set in tfvars
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.secondary_origin_hostname
  priority                       = 2
  weight                         = 1000
  certificate_name_check_enabled = false
}

# -----------------------------------------------------------------------------
# Route – catch-all
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${var.project_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [
    azurerm_cdn_frontdoor_origin.primary.id,
    azurerm_cdn_frontdoor_origin.secondary.id,
  ]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpOnly"   # change to HttpsOnly / MatchRequest once TLS is ready
  link_to_default_domain = true
  https_redirect_enabled = false
}