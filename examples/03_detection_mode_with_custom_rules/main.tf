module "frontdoor_policy" {
  source = "../.."

  name                = var.policy_name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags

  policy_settings = { mode = "Detection" }

  managed_rule_sets = [{
    type    = "Microsoft_DefaultRuleSet"
    version = "2.2"
    action  = "Block"
    rule_group_overrides = [{
      rule_group_name = "SQLI"
      rules = [{
        rule_id = "942100"
        enabled = true
        action  = "Log"
        # Exclude only this reviewed argument from this specific rule.
        exclusions = [{
          match_variable = "QueryStringArgNames"
          operator       = "Equals"
          selector       = "search"
        }]
      }]
    }]
  }]

  custom_rules = [
    {
      name     = "ObserveAdminBoundary"
      priority = 10
      action   = "Block"
      match_conditions = [
        {
          match_variable = "RequestUri"
          operator       = "Contains"
          match_values   = ["/admin"]
          transforms     = ["Lowercase"]
        },
        {
          match_variable     = "SocketAddr"
          operator           = "IPMatch"
          negation_condition = true
          match_values       = var.approved_client_cidrs
        }
      ]
    },
    {
      name                           = "ObserveLoginRate"
      priority                       = 20
      type                           = "RateLimitRule"
      action                         = "Block"
      rate_limit_duration_in_minutes = 5
      rate_limit_threshold           = 200
      match_conditions = [{
        match_variable = "RequestUri"
        operator       = "Contains"
        match_values   = ["/login"]
        transforms     = ["Lowercase"]
      }]
    }
  ]
}
