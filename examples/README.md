# Azure Front Door Web Application Firewall Policies with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-frontdoor-waf-policy** module.
Example 01 is a complete **Prevention mini-architecture** with its own application and diagnostics. Examples 02 and 03 currently demonstrate narrower composition and tuning contracts; their expansion into complete labs is a later step.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and are intended for Azure courses focused on independently governed Front Door application security.

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| [01](01_basic_prevention_policy) | **Prevention Mini-Architecture** | Front Door Premium, DRS 2.2 Block, NGINX backend, origin protection, NAT Gateway and diagnostics |
| [02](02_policy_attached_to_frontdoor) | **Policy Attached to Front Door** | Front Door v0.1.0 composition, matching Premium SKU, policy-ID attachment, sibling-owned security association |
| [03](03_detection_mode_with_custom_rules) | **Detection Mode with Custom Rules** | Admin-path IP boundary, native login rate limit, managed-rule override, rule-scoped exclusion, tuning before enforcement |

Each example builds on the **concepts** introduced in the previous one, but can be applied independently for learning and experimentation.

---

## ⚙️ How to Use

Each example directory contains:

- Terraform/OpenTofu configuration (`.tf`)
- A focused `README.md` explaining the goal of the example
- A safe `terraform.tfvars.example` without credentials or secrets
- An architecture diagram distinguishing created resources from external dependencies
- Azure Portal screenshot checklists and a runtime verification procedure

To validate the first example:

```bash
cd examples/01_basic_prevention_policy
cp terraform.tfvars.example terraform.tfvars
tofu fmt -check
tofu init
tofu validate
```

Example 01 creates a dedicated Resource Group, network and NGINX application. Replace the illustrative subscription ID and choose a globally unique endpoint name. Azure authentication is supplied externally. Examples 02 and 03 currently need an existing Resource Group; example 02 additionally needs an existing publicly reachable HTTPS origin.

For a later deployment, review the configuration and costs before running:

```bash
tofu plan
tofu apply
```

The recommended learning sequence is:
01 → 02 → 03

All three examples passed static formatting, initialization and validation with AzureRM 4.81.0 on October 9, 2026. Example 01 was subsequently deployed with explicit approval (28 resources added across a policy bootstrap and full apply). After initial Front Door propagation, runtime tests confirmed benign HTTP 200, controlled XSS HTTP 403 with a correlated managed-rule `Block`, and origin-access restrictions. Its README contains actual screenshots and test evidence. Examples 02 and 03 have not been deployed.

Example 01 includes its attachment and real backend, providing a complete path for future HTTP enforcement tests. Example 03 currently creates only a Front Door policy and requires an external attachment for traffic testing. Example 02 creates its attachment through the pinned sibling module but uses an external origin.

---

## 🧩 Design Principles

- One example = one architectural goal
- Front Door security policy governance is independent of profile lifecycle
- The root module creates one Front Door policy; the consuming sibling owns delivery and attachment
- Example 01 owns an isolated lab environment; remaining examples document their external dependencies
- No secrets or subscription-specific values in source control
- Static validation is not represented as successful runtime deployment

These examples intentionally avoid:

- Full landing zones or orchestrator patterns
- Hidden dependencies between examples
- Creating Front Door delivery or attachment resources inside the root policy module
- Creating Application Gateway policies or Azure Firewall resources

---

## 🧩 Related Resources

- [FoggyKitchen Front Door Policy Module (terraform-az-fk-frontdoor-waf-policy)](../)
- [FoggyKitchen Azure Front Door Module (terraform-az-fk-frontdoor)](https://github.com/foggykitchen/terraform-az-fk-frontdoor)
- [FoggyKitchen Application Gateway Policy Module (terraform-az-fk-waf-policy)](https://github.com/foggykitchen/terraform-az-fk-waf-policy)
- [FoggyKitchen Azure Firewall Module (terraform-az-fk-firewall)](https://github.com/foggykitchen/terraform-az-fk-firewall)
- [Azure Front Door application security documentation](https://learn.microsoft.com/azure/web-application-firewall/afds/afds-overview)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
