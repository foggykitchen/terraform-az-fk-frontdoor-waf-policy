locals {
  # Preserve scope and set metadata when validating all three exclusion levels.
  exclusion_scopes = flatten([for s in var.managed_rule_sets : concat(
    [{ type = s.type, version = s.version, exclusions = s.exclusions }],
    [for g in s.rule_group_overrides : { type = s.type, version = s.version, exclusions = g.exclusions }],
    flatten([for g in s.rule_group_overrides : [
      for r in g.rules : { type = s.type, version = s.version, exclusions = r.exclusions }
    ]])
  )])
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  sku_name                          = var.sku_name
  enabled                           = var.policy_settings.enabled
  mode                              = var.policy_settings.mode
  request_body_check_enabled        = var.policy_settings.request_body_check_enabled
  redirect_url                      = var.policy_settings.redirect_url
  custom_block_response_status_code = var.policy_settings.custom_block_response_status_code
  custom_block_response_body        = var.policy_settings.custom_block_response_body
  tags                              = var.tags

  dynamic "managed_rule" {
    for_each = var.managed_rule_sets
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action
      dynamic "exclusion" {
        for_each = managed_rule.value.exclusions
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }
      dynamic "override" {
        for_each = managed_rule.value.rule_group_overrides
        content {
          rule_group_name = override.value.rule_group_name
          dynamic "exclusion" {
            for_each = override.value.exclusions
            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }
          dynamic "rule" {
            for_each = override.value.rules
            content {
              rule_id = rule.value.rule_id
              enabled = rule.value.enabled
              action  = rule.value.action
              dynamic "exclusion" {
                for_each = rule.value.exclusions
                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      name                           = custom_rule.value.name
      priority                       = custom_rule.value.priority
      type                           = custom_rule.value.type
      action                         = custom_rule.value.action
      enabled                        = custom_rule.value.enabled
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          match_values       = match_condition.value.match_values
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.sku_name == "Premium_AzureFrontDoor" || (length(var.managed_rule_sets) == 0 && alltrue([for r in var.custom_rules : !contains(["JSChallenge", "CAPTCHA"], r.action)]))
      error_message = "Managed rules and challenge actions require Premium_AzureFrontDoor. Standard callers must set managed_rule_sets = []."
    }
    precondition {
      condition = alltrue([for scope in local.exclusion_scopes :
        length(scope.exclusions) <= 100 && alltrue([for e in scope.exclusions :
          contains(["QueryStringArgNames", "RequestBodyPostArgNames", "RequestCookieNames", "RequestHeaderNames", "RequestBodyJsonArgNames"], e.match_variable) &&
          contains(["Equals", "Contains", "StartsWith", "EndsWith", "EqualsAny"], e.operator) &&
          trimspace(e.selector) != "" && (e.operator != "EqualsAny" || e.selector == "*") &&
          (e.match_variable != "RequestBodyJsonArgNames" || (scope.type == "Microsoft_DefaultRuleSet" && contains(["2.0", "2.1", "2.2"], scope.version)))
        ])
      ])
      error_message = "Exclusions require valid Front Door variables/operators, nonempty selectors and at most 100 per scope. EqualsAny requires *; JSON exclusions require DRS 2.x."
    }
    precondition {
      condition     = !anytrue(concat([for s in var.managed_rule_sets : s.action == "Redirect"], [for s in var.managed_rule_sets : anytrue(flatten([for g in s.rule_group_overrides : [for r in g.rules : r.action == "Redirect"]]))], [for r in var.custom_rules : r.action == "Redirect"])) || var.policy_settings.redirect_url != null
      error_message = "Redirect actions require policy_settings.redirect_url."
    }
  }
}
