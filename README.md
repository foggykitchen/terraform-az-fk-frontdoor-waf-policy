# terraform-az-fk-frontdoor-waf-policy

This repository contains a reusable **Terraform / OpenTofu module** and progressive examples for deploying a standalone **Azure Front Door Web Application Firewall Policy** — starting from a minimal Prevention policy and evolving toward independent Front Door attachment, custom rules, rate limiting, exclusions, and Detection-mode tuning.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and is designed as a **clean, composable application security layer** that can be centrally governed, versioned, and audited independently of any Front Door profile lifecycle.

This module owns Front Door's `azurerm_cdn_frontdoor_firewall_policy`. Application Gateway's distinct `azurerm_web_application_firewall_policy` belongs to [terraform-az-fk-waf-policy](https://github.com/foggykitchen/terraform-az-fk-waf-policy); Azure Firewall and network-layer rules belong to [terraform-az-fk-firewall](https://github.com/foggykitchen/terraform-az-fk-firewall). These products and policy resource IDs are not interchangeable.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is designed to be used as a focused building block wherever centrally governed Front Door Web Application Firewall Policies are composed with independently managed Front Door profiles.

## 🎯 Purpose

Create one Front Door Web Application Firewall Policy, including its mode, SKU, managed rule sets, custom match/rate-limit rules and scoped exclusions. Reference its ID from one or more [terraform-az-fk-frontdoor](https://github.com/foggykitchen/terraform-az-fk-frontdoor) instances through that module's `frontdoor_firewall_policy_id` input.

The relationship mirrors the independently governed Application Gateway policy sibling, while respecting Front Door's separate resource type and rule schema.

---

## ✨ What the module does

The module creates:

- One `azurerm_cdn_frontdoor_firewall_policy`
- Standard/Premium SKU, enabled state, Detection/Prevention mode and request body inspection
- Managed rule sets with per-group and per-rule state/action overrides
- Custom match and native rate-limit rules
- Managed-set, group and rule-scoped exclusions
- Optional redirect and custom block response settings

The module intentionally does not create:

- Front Door profiles, endpoints, origin groups, origins or routes — owned by terraform-az-fk-frontdoor
- The `azurerm_cdn_frontdoor_security_policy` association — owned by terraform-az-fk-frontdoor, consuming this policy's ID
- Application Gateway or its `azurerm_web_application_firewall_policy` — owned by terraform-az-fk-application-gateway / terraform-az-fk-waf-policy
- Azure Firewall or network-layer firewall rules — owned by terraform-az-fk-firewall
- Resource Groups, VNets, subnets or other networking resources
- Diagnostic settings or Log Analytics Workspaces

Each concern belongs in its own dedicated module. A Front Door policy does not inspect traffic until a consuming Front Door security-policy association attaches it.

---

## Provider Notes

Live discovery on **2026-10-09** verified the [AzureRM 4.81.0 resource documentation](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/cdn_frontdoor_firewall_policy.html.markdown), [resource schema and expansion logic](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/internal/services/cdn/cdn_frontdoor_firewall_policy_resource.go), and [name validator](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/internal/services/cdn/validate/front_door_firewall_policy_name.go). This release uses **Microsoft.Network API `2025-03-01`** for `frontDoorWebApplicationFirewallPolicies`. The policy is a Resource Group-level **global** resource: the provider sets location to global. There is no `location`, profile name or profile ID argument.

The static FoggyKitchen constraint remains `>= 3.100.0, < 5.0.0`. The [live registry](https://registry.terraform.io/providers/hashicorp/azurerm) lists **4.81.0** as latest within this range; [5.9.0](https://github.com/hashicorp/terraform-provider-azurerm/releases/tag/v5.9.0) is latest overall. Its [current resource source](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.9.0/internal/services/cdn/cdn_frontdoor_firewall_policy_resource.go) also imports API `2025-03-01`. **Use AzureRM 4.81.0 for the verified complete contract.** The [3.100.0 schema documentation](https://github.com/hashicorp/terraform-provider-azurerm/blob/v3.100.0/website/docs/r/cdn_frontdoor_firewall_policy.html.markdown) and [source](https://github.com/hashicorp/terraform-provider-azurerm/blob/v3.100.0/internal/services/cdn/cdn_frontdoor_firewall_policy_resource.go) already include the core fields, native rate limits and all three exclusion scopes, so no higher floor is needed for the examples. The root validates with both 3.100.0 and 4.81.0; all examples validate with 4.81.0. Challenge actions and extended block statuses need newer provider support; the range does not promise every optional capability on every older release. Run `tofu init -upgrade` for older locks. Lock files are intentionally ignored.

### Managed rules

The default is `Microsoft_DefaultRuleSet` version **`2.2`**, action `Block`. [Microsoft recommends DRS 2.2 for new Front Door Premium deployments](https://learn.microsoft.com/en-us/azure/networking/design-guide/web-application-firewall), and its [Front Door-specific DRS reference](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-drs) documents the rule groups. This is the same default type/version as terraform-az-fk-waf-policy, but the schemas remain distinct.

**Documentation discrepancy:** both [4.81.0](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/cdn_frontdoor_firewall_policy.html.markdown) and [current 5.9.0 provider prose](https://github.com/hashicorp/terraform-provider-azurerm/blob/v5.9.0/website/docs/r/cdn_frontdoor_firewall_policy.html.markdown) list Microsoft DRS versions only through 2.1. The 4.81.0 source checks nonempty type/version strings and permits Microsoft_DefaultRuleSet versions >=1.1, including 2.2. Its DRS >=2.0 override logic also accepts 2.2. Static validation establishes provider compatibility, not service-side deployment acceptance; no policy has been deployed for this verification.

| Front Door type | Supported contract versions | Notes |
|------|--------------------|-------|
| `Microsoft_DefaultRuleSet` | `1.1`, `2.0`, `2.1`, `2.2` | Default 2.2; Premium |
| `DefaultRuleSet` | `1.0`, `preview-0.1` | Legacy; prefer current DRS |
| `Microsoft_BotManagerRuleSet` | `1.0`, `1.1` | Optional bot set; Premium |
| `BotProtection` | `preview-0.1` | Legacy bot set |

The module permits at most one baseline and one bot set, or no managed sets. It validates type/version pairing and unique types/groups/rule IDs. Front Door does not use the Application Gateway `OWASP` type or CRS version table. Newer service features such as HTTP DDoS sensitivity and exception controls are outside this verified contract.

`managed_rule_sets[].rule_group_overrides[]` maps to provider `managed_rule { override { rule { rule_id, enabled, action } } }`. **An override rule defaults to disabled**, matching the provider. Set `enabled = true` explicitly to change only its action. An override group with no rules disables the entire group. Omitted groups/rules keep Azure defaults; rule IDs must belong to the chosen rule set.

Managed-set actions are `Allow`, `Block`, `Log`, `Redirect`. For DRS 2.x, per-rule overrides must be `AnomalyScoring` or `Log`; these are separate from the set's aggregate action. Earlier DRS uses individual-match actions. Bot Manager permits `Allow`, `Block`, `Log`, `Redirect`, `JSChallenge` and provider-exposed `CAPTCHA`; service availability must be checked before selecting preview challenge behavior. JavaScript rule overrides require Bot Manager. DRS 2.2 operates with PL1 defaults; do not enable additional rules without reviewing their effect.

### Custom rules and mode

[Front Door custom rules](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-custom-rules) evaluate by unique integer priority, lowest first. The module requires positive integer priorities and unique names. Up to 100 custom rules are supported. Custom rules run before managed rules; `Log` continues evaluation, while terminating actions can bypass subsequent managed inspection. Prefer a narrow negated-IP Block boundary over a broad Allow exception.

Detection mode monitors and logs matches while allowing traffic, including custom Block rules. Use it for tuning, then review logs before switching to Prevention. DRS 2.x accumulates anomaly scores and applies the configured set action at the threshold.

The resource supports `MatchRule` and `RateLimitRule`. Custom actions are `Allow`, `Block`, `Log`, `Redirect`, `JSChallenge` and `CAPTCHA`. Challenge actions require Premium and newer providers; challenge cookie lifetimes and log scrubbing remain outside this module. Redirect actions require `policy_settings.redirect_url`.

Each rule requires 1..10 match conditions. Each condition uses one `match_variable`, not Application Gateway's nested match-variable blocks. Variables: `Cookies`, `PostArgs`, `QueryString`, `RemoteAddr`, `RequestBody`, `RequestHeader`, `RequestMethod`, `RequestUri`, `SocketAddr`. `RemoteAddr` inspects the original client IP from X-Forwarded-For; `SocketAddr` is the source IP seen by Front Door. Selectors apply only to Cookies/PostArgs/QueryString/RequestHeader.

Exact provider operators: `Any`, `BeginsWith`, `Contains`, `EndsWith`, `Equal`, `GeoMatch`, `GreaterThan`, `GreaterThanOrEqual`, `IPMatch`, `LessThan`, `LessThanOrEqual`, `RegEx`. Values are required unless Any; still supply `match_values = []` for Any. Up to 600 values across a rule, each 1..256 characters. Conditions combine with AND and values with OR. Up to five transforms, in list order: `Lowercase`, `RemoveNulls`, `Trim`, `Uppercase`, `URLDecode`, `URLEncode`. Casing differs from Application Gateway.

[Native Front Door rate limiting](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-rate-limit) works with Standard and Premium. Set type RateLimitRule, a positive integer threshold and duration **1 or 5 minutes** (default 1). Counters are per socket IP; no `group_rate_limit_by` argument exists here. Edge-server counters make enforcement approximate, especially for short windows or low thresholds. Shared policies do not imply one globally synchronized quota. MatchRule must omit rate fields; the provider still applies its own 1-minute/10-request defaults internally.

### Inspection and exclusions

`policy_settings` is a singleton object: enabled and request body check default true, mode defaults Prevention. Front Door's provider exposes no Application Gateway body/file inspection-limit arguments. Response customization is optional: redirect URL, block status and base64 UTF-8 block body. The provider accepts statuses 200, 403, 405, 406, 429 and 990..999; 3.100.0 supports only the first five.

Exclusions belong within each managed set, override group or override rule. There is no top-level global exclusion block. A set-level exclusion applies throughout that set; a group exclusion applies within that group; a rule exclusion applies only to the selected rule. Up to 100 exclusions per scope. Prefer narrowly scoped exact exclusions.

Front Door exclusion variables are `QueryStringArgNames`, `RequestBodyPostArgNames`, `RequestCookieNames`, `RequestHeaderNames`, `RequestBodyJsonArgNames`; JSON argument exclusions require Microsoft DRS 2.x. Operators are `Equals`, `Contains`, `StartsWith`, `EndsWith`, `EqualsAny`. EqualsAny requires `selector = "*"`. Regex exclusions are unsupported; exclusions do not apply to custom rules.

### Diagnostics and sharing

The policy SKU must [match the consuming Front Door profile tier](https://learn.microsoft.com/en-us/azure/frontdoor/how-to-configure-endpoints). Use Premium for managed rules. To use Standard, explicitly set `sku_name = "Standard_AzureFrontDoor"` and `managed_rule_sets = []`; native custom rate limits remain available.

The sibling's `frontdoor_firewall_policy_id` is an optional string defaulting to null. Its `security_policy_name` names the association and defaults to `default-security-policy`; it is independent of this policy's name. The [4.81.0 association docs](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/cdn_frontdoor_security_policy.html.markdown) and [source](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/internal/services/cdn/cdn_frontdoor_security_policy_resource.go) require a profile ID, policy ID and endpoint/custom-domain association with `/*`. Limits are 100 domains for Standard and 500 for Premium. This association uses Microsoft.Cdn API `2025-12-01`, separately from the policy's Microsoft.Network API. The current sibling associates its single default endpoint.

A policy can be referenced by multiple compatible Front Door consumers. All consumers share rule updates; govern those changes centrally and detach associations before deleting it. [Front Door diagnostics](https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-logs) are configured on consuming profiles through the sibling's `diagnostic_settings`, with external Log Analytics workspace IDs. This policy module accepts no workspace ID.

---

## 📂 Repository Structure

```text
terraform-az-fk-frontdoor-waf-policy/
├── examples/
│   ├── 01_basic_prevention_policy/
│   ├── 02_policy_attached_to_frontdoor/
│   ├── 03_detection_mode_with_custom_rules/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── SUPPORT.md
├── LICENSE
└── README.md
```

Each example contains `main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars.example`, and `README.md`. Root inputs follow the sibling convention of `inputs.tf`; example inputs live in `variables.tf`. Example documentation includes architecture diagrams, Azure Portal evidence checklists, validation results and cleanup steps.

---

## 🚀 Example Usage

```hcl
module "frontdoor_policy" {
  source = "./terraform-az-fk-frontdoor-waf-policy"

  name                = "fkSharedFrontDoorPolicy"
  resource_group_name = "fk-security-rg"
  tags                = { project = "foggykitchen", env = "dev" }
}

# Inside each separately composed terraform-az-fk-frontdoor module:
sku_name                     = module.frontdoor_policy.frontdoor_firewall_policy_sku_name
frontdoor_firewall_policy_id = module.frontdoor_policy.frontdoor_firewall_policy_id
security_policy_name         = "shared-frontdoor-policy"
```

See example 02 for a complete runnable composition with the latest Front Door tag discovered, `v0.1.0`. Keep endpoint, origin and route configuration in that sibling.

---

## 📥 Module Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | `string` | yes | — | Name of the Azure Front Door Web Application Firewall Policy. |
| `resource_group_name` | `string` | yes | — | Existing Resource Group containing the Front Door Web Application Firewall Policy. |
| `sku_name` | `string` | no | `Premium_AzureFrontDoor` | Front Door policy SKU; use the same SKU as each consuming Front Door profile. |
| `policy_settings` | `object` | no | `{}` | Front Door policy mode, enabled state, body inspection and optional response customization. |
| `managed_rule_sets` | `list(object)` | no | `[{}]` | Front Door managed rule sets with set/group/rule exclusions and overrides; default Microsoft Default Rule Set 2.2. |
| `custom_rules` | `list(object)` | no | `[]` | Front Door custom match or rate-limit rules with unique names and priorities. |
| `tags` | `map(string)` | no | `{}` | Tags assigned to the Front Door Web Application Firewall Policy. |

### Object schemas

The complete typed object inputs, including nested defaults, are:

```hcl
policy_settings = object({
    enabled                           = optional(bool, true)
    mode                              = optional(string, "Prevention")
    request_body_check_enabled        = optional(bool, true)
    redirect_url                      = optional(string)
    custom_block_response_status_code = optional(number)
    custom_block_response_body        = optional(string)
  })
```

```hcl
managed_rule_sets = list(object({
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
```

```hcl
custom_rules = list(object({
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
```

---

## 📤 Module Outputs

| Output | Description |
|--------|-------------|
| `frontdoor_firewall_policy_id` | The ID of the Azure Front Door Web Application Firewall Policy. |
| `frontdoor_firewall_policy_name` | The name of the Azure Front Door Web Application Firewall Policy. |
| `frontdoor_firewall_policy_sku_name` | The SKU of the Azure Front Door Web Application Firewall Policy. |

---

## 🧭 Examples

- `01_basic_prevention_policy`: minimal Premium Prevention policy using DRS 2.2 with Block action
- `02_policy_attached_to_frontdoor`: policy-ID composition with the pinned Front Door v0.1.0 module, Premium SKU and sibling-owned security association
- `03_detection_mode_with_custom_rules`: Detection tuning with an admin IP boundary, login rate limit, managed override and scoped exclusion

See [examples/README.md](examples/README.md). Examples use an existing Resource Group. Example 02 also creates Front Door delivery resources through the sibling and references an existing public origin. All three examples passed fmt/init/validate with AzureRM 4.81.0 on 2026-10-09. Both original Front Door examples also passed validation in an isolated checkout. No plan, apply, deployed traffic or real-subscription check was performed. Each example documents the evidence to collect during future deployment testing.

---

## 🧠 Design Philosophy

- Explicit inputs and policy-ID composition
- Central governance independent of Front Door profile lifecycle
- Small modules over monoliths
- Front Door application security separated from networking, application delivery and monitoring destinations
- Optimized for learning, reuse and auditability

---

## 🧩 Related Modules & Training

- [terraform-az-fk-frontdoor](https://github.com/foggykitchen/terraform-az-fk-frontdoor)
- [terraform-az-fk-waf-policy](https://github.com/foggykitchen/terraform-az-fk-waf-policy) — Application Gateway policy
- [terraform-az-fk-application-gateway](https://github.com/foggykitchen/terraform-az-fk-application-gateway)
- [terraform-az-fk-firewall](https://github.com/foggykitchen/terraform-az-fk-firewall) — network firewall
- [terraform-az-fk-log-analytics](https://github.com/foggykitchen/terraform-az-fk-log-analytics)

See [examples](examples/README.md) for progressive Front Door Web Application Firewall Policy scenarios.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
