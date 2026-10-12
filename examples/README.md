# Azure Front Door Web Application Firewall Policies with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-frontdoor-waf-policy** module.
Example 01 is a complete **Prevention mini-architecture** with its own application and diagnostics. Example 02 extends this into **two independent applications sharing one Front Door policy**. Example 03 is a complete **Detection tuning lab** based on example 01, with custom rules, native login rate limiting, a managed-rule override and a scoped exclusion.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and are intended for Azure courses focused on independently governed Front Door application security.

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| [01](01_basic_prevention_policy) | **Prevention Mini-Architecture** | Front Door Premium, DRS 2.2 Block, NGINX backend, origin protection, NAT Gateway and diagnostics |
| [02](02_policy_attached_to_frontdoor) | **One Policy, Two Applications** | Two Premium profiles, one shared Front Door policy, separate private NGINX backends and origin trust boundaries, shared diagnostics |
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

All three examples create dedicated Resource Groups, networks and NGINX applications. Replace the illustrative subscription ID and choose globally unique endpoint names (two in example 02). Azure authentication is supplied externally. Example 03 also requires reviewed approved admin client CIDRs. All examples document the one-time policy bootstrap required by the pinned Front Door v0.1.0 association count.

For a later deployment, review the configuration and costs before running:

```bash
tofu plan
tofu apply
```

The recommended learning sequence is:
01 → 02 → 03

All three examples passed static formatting, initialization and validation with AzureRM 4.81.0 on October 9, 2026. Example 01 was subsequently deployed with explicit approval (28 resources added across a policy bootstrap and full apply). After initial Front Door propagation, runtime tests confirmed benign HTTP 200, controlled XSS HTTP 403 with a correlated managed-rule `Block`, and origin-access restrictions. Its README contains actual screenshots and test evidence. The lab was then destroyed: 28 resources removed, empty state and Resource Group absence confirmed. Example 02 was deployed with explicit approval (48 resources added across bootstrap and full apply). Runtime tests passed on both profiles, including exact-reference managed-rule Block correlation; its README records actual logs and screenshots. Example 02 was subsequently destroyed: 48 resources removed, empty state and Resource Group absence confirmed. Example 03 was deployed with explicit approval on October 12, 2026: 28 resources added, policy Enabled/Premium/Detection and active association confirmed. Example 03 was subsequently destroyed: 28 resources removed, empty state and Resource Group absence confirmed. Its README records configuration screenshots with Figure 1–8 captions; runtime tests were not performed before cleanup.

Examples 01 and 02 include their attachments and real backends. Example 02's runtime tests passed for both applications: benign HTTP 200, XSS HTTP 403 with correlated managed-rule Block records, shared policy-ID associations, direct-origin restrictions and cross-profile identifier rejection on the local NGINX listeners. Its README contains actual test logs and screenshots with Figure 1–18 captions. Example 03 includes its own Front Door profile, association, private NGINX backend and diagnostics; the expanded configuration passed static validation and was deployed. Its README records configuration screenshots, but runtime tests were not performed before cleanup.

---

## 🧩 Design Principles

- One example = one architectural goal
- Front Door security policy governance is independent of profile lifecycle
- The root module creates one Front Door policy; the consuming sibling owns delivery and attachment
- All three examples own isolated lab environments; deployment and enforcement changes require explicit approval
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
