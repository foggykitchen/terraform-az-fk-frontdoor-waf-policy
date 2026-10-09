module "frontdoor_policy" {
  source = "../.."

  name                = var.policy_name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags
}

module "frontdoor" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-frontdoor.git?ref=v0.1.0"

  name                         = var.frontdoor_name
  resource_group_name          = var.resource_group_name
  sku_name                     = module.frontdoor_policy.frontdoor_firewall_policy_sku_name
  endpoint                     = { name = var.endpoint_name }
  frontdoor_firewall_policy_id = module.frontdoor_policy.frontdoor_firewall_policy_id
  security_policy_name         = "shared-frontdoor-policy"
  tags                         = var.tags

  origin_groups = {
    web = { health_probe = { path = "/" } }
  }
  origins = {
    web = {
      origin_group_key   = "web"
      host_name          = var.origin_host_name
      origin_host_header = var.origin_host_name
    }
  }
  routes = {
    default = {
      origin_group_key  = "web"
      patterns_to_match = ["/*"]
    }
  }
}
