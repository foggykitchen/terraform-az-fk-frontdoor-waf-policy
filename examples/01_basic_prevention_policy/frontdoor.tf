module "frontdoor" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-frontdoor.git?ref=v0.1.0"

  name                         = "${var.name_prefix}-frontdoor"
  resource_group_name          = azurerm_resource_group.foggykitchen_rg.name
  sku_name                     = module.frontdoor_policy.frontdoor_firewall_policy_sku_name
  endpoint                     = { name = var.endpoint_name }
  frontdoor_firewall_policy_id = module.frontdoor_policy.frontdoor_firewall_policy_id
  security_policy_name         = "prevention-security-policy"

  origin_groups = {
    web = {
      health_probe = {
        path         = "/health"
        protocol     = "Http"
        request_type = "HEAD"
      }
    }
  }
  origins = {
    nginx = {
      origin_group_key               = "web"
      host_name                      = module.load_balancer.public_ip_address
      certificate_name_check_enabled = false
      http_port                      = 80
      priority                       = 1
      weight                         = 1000
    }
  }
  routes = {
    default = {
      origin_group_key    = "web"
      patterns_to_match   = ["/*"]
      forwarding_protocol = "HttpOnly"
    }
  }
  diagnostic_settings = {
    lab = {
      log_analytics_workspace_id     = module.log_analytics.id
      log_analytics_destination_type = "AzureDiagnostics"
    }
  }
  tags = var.tags
}
