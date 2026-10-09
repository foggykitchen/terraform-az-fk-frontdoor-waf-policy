variable "name" {
  nullable    = false
  description = "Name of the Azure Front Door Web Application Firewall Policy."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,127}$", var.name))
    error_message = "name must be 1..128 alphanumeric characters and begin with a letter."
  }
}

variable "resource_group_name" {
  nullable    = false
  description = "Existing Resource Group containing the Front Door Web Application Firewall Policy."
  type        = string
  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "sku_name" {
  nullable    = false
  description = "Front Door policy SKU; use the same SKU as each consuming Front Door profile."
  type        = string
  default     = "Premium_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "policy_settings" {
  nullable    = false
  description = "Front Door policy mode, enabled state, body inspection and optional response customization."
  type = object({
    enabled                           = optional(bool, true)
    mode                              = optional(string, "Prevention")
    request_body_check_enabled        = optional(bool, true)
    redirect_url                      = optional(string)
    custom_block_response_status_code = optional(number)
    custom_block_response_body        = optional(string)
  })
  default = {}
  validation {
    condition = (
      contains(["Detection", "Prevention"], var.policy_settings.mode) &&
      (var.policy_settings.redirect_url == null ? true : can(regex("^https?://[^/[:space:]]+", var.policy_settings.redirect_url))) &&
      (var.policy_settings.custom_block_response_status_code == null ? true : contains([200, 403, 405, 406, 429, 990, 991, 992, 993, 994, 995, 996, 997, 998, 999], var.policy_settings.custom_block_response_status_code)) &&
      (var.policy_settings.custom_block_response_body == null ? true : can(base64decode(var.policy_settings.custom_block_response_body)))
    )
    error_message = "Use Detection or Prevention, an HTTP(S) redirect URL, a supported block status and a base64-encoded UTF-8 response body."
  }
}

variable "managed_rule_sets" {
  nullable    = false
  description = "Front Door managed rule sets with set/group/rule exclusions and overrides; default Microsoft Default Rule Set 2.2."
  type = list(object({
    type    = optional(string, "Microsoft_DefaultRuleSet")
    version = optional(string, "2.2")
    action  = optional(string, "Block")
    exclusions = optional(list(object({
      match_variable = string
      operator       = string
      selector       = string
    })), [])
    rule_group_overrides = optional(list(object({
      rule_group_name = string
      exclusions = optional(list(object({
        match_variable = string
        operator       = string
        selector       = string
      })), [])
      rules = optional(list(object({
        rule_id = string
        enabled = optional(bool, false)
        action  = string
        exclusions = optional(list(object({
          match_variable = string
          operator       = string
          selector       = string
        })), [])
      })), [])
    })), [])
  }))
  default = [{}]
  validation {
    condition = (
      length(var.managed_rule_sets) <= 2 &&
      length(distinct([for s in var.managed_rule_sets : s.type])) == length(var.managed_rule_sets) &&
      length([for s in var.managed_rule_sets : s if contains(["DefaultRuleSet", "Microsoft_DefaultRuleSet"], s.type)]) <= 1 &&
      length([for s in var.managed_rule_sets : s if contains(["BotProtection", "Microsoft_BotManagerRuleSet"], s.type)]) <= 1 &&
      alltrue([for s in var.managed_rule_sets :
        contains(lookup({
          DefaultRuleSet              = ["preview-0.1", "1.0"]
          Microsoft_DefaultRuleSet    = ["1.1", "2.0", "2.1", "2.2"]
          BotProtection               = ["preview-0.1"]
          Microsoft_BotManagerRuleSet = ["1.0", "1.1"]
        }, s.type, []), s.version) &&
        contains(["Allow", "Block", "Log", "Redirect"], s.action) &&
        length(s.rule_group_overrides) <= 100 &&
        length(distinct([for g in s.rule_group_overrides : g.rule_group_name])) == length(s.rule_group_overrides)
      ]) &&
      alltrue(flatten([for s in var.managed_rule_sets : [for g in s.rule_group_overrides :
        trimspace(g.rule_group_name) != "" && length(g.rules) <= 1000 &&
        length(distinct([for r in g.rules : r.rule_id])) == length(g.rules) &&
        alltrue([for r in g.rules : trimspace(r.rule_id) != "" && (
          s.type == "Microsoft_DefaultRuleSet" && contains(["2.0", "2.1", "2.2"], s.version) ?
          contains(["AnomalyScoring", "Log"], r.action) :
          contains(s.type == "Microsoft_BotManagerRuleSet" ? ["Allow", "Block", "Log", "Redirect", "JSChallenge", "CAPTCHA"] : ["Allow", "Block", "Log", "Redirect", "CAPTCHA"], r.action)
        )])
      ]]))
    )
    error_message = "Use supported Front Door type/version pairs, at most one baseline and one bot set, unique types/groups/rule IDs and valid actions. DRS 2.x overrides require AnomalyScoring or Log."
  }
}

variable "custom_rules" {
  nullable    = false
  description = "Front Door custom match or rate-limit rules with unique names and priorities."
  type = list(object({
    name                           = string
    priority                       = number
    type                           = optional(string, "MatchRule")
    action                         = string
    enabled                        = optional(bool, true)
    rate_limit_duration_in_minutes = optional(number)
    rate_limit_threshold           = optional(number)
    match_conditions = list(object({
      match_variable     = string
      operator           = string
      match_values       = list(string)
      selector           = optional(string)
      negation_condition = optional(bool, false)
      transforms         = optional(list(string), [])
    }))
  }))
  default = []
  validation {
    condition = (
      length(var.custom_rules) <= 100 &&
      length(distinct([for r in var.custom_rules : r.name])) == length(var.custom_rules) &&
      length(distinct([for r in var.custom_rules : r.priority])) == length(var.custom_rules) &&
      alltrue([for r in var.custom_rules :
        trimspace(r.name) != "" && r.priority >= 1 && floor(r.priority) == r.priority &&
        contains(["MatchRule", "RateLimitRule"], r.type) &&
        contains(["Allow", "Block", "Log", "Redirect", "JSChallenge", "CAPTCHA"], r.action) &&
        length(r.match_conditions) >= 1 && length(r.match_conditions) <= 10 &&
        sum([for c in r.match_conditions : length(c.match_values)]) <= 600 &&
        (r.type == "RateLimitRule" ? (
          contains([1, 5], coalesce(r.rate_limit_duration_in_minutes, 1)) &&
          (r.rate_limit_threshold == null ? false : r.rate_limit_threshold >= 1 && floor(r.rate_limit_threshold) == r.rate_limit_threshold)
        ) : r.rate_limit_duration_in_minutes == null && r.rate_limit_threshold == null)
      ]) &&
      alltrue(flatten([for r in var.custom_rules : [for c in r.match_conditions :
        contains(["Cookies", "PostArgs", "QueryString", "RemoteAddr", "RequestBody", "RequestHeader", "RequestMethod", "RequestUri", "SocketAddr"], c.match_variable) &&
        contains(["Any", "BeginsWith", "Contains", "EndsWith", "Equal", "GeoMatch", "GreaterThan", "GreaterThanOrEqual", "IPMatch", "LessThan", "LessThanOrEqual", "RegEx"], c.operator) &&
        (c.operator == "Any" || length(c.match_values) > 0) &&
        alltrue([for v in c.match_values : length(v) >= 1 && length(v) <= 256]) &&
        (c.selector == null ? true : trimspace(c.selector) != "" && contains(["Cookies", "PostArgs", "QueryString", "RequestHeader"], c.match_variable)) &&
        length(c.transforms) <= 5 &&
        alltrue([for t in c.transforms : contains(["Lowercase", "RemoveNulls", "Trim", "Uppercase", "URLDecode", "URLEncode"], t)])
      ]]))
    )
    error_message = "Custom rules require unique names/positive integer priorities, valid conditions/actions, 1..10 conditions, at most 600 values and 5 transforms. RateLimitRule requires a positive integer threshold and duration 1 or 5; MatchRule omits rate fields."
  }
}

variable "tags" {
  nullable    = false
  description = "Tags assigned to the Front Door Web Application Firewall Policy."
  type        = map(string)
  default     = {}
}
