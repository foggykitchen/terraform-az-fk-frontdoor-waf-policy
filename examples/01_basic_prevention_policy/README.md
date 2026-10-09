# Example 01: Prevention (Front Door Application Security Basics)

This lab creates a complete mini-architecture: Front Door Premium, a separately managed Front Door Web Application Firewall Policy in Prevention mode, and a private NGINX application behind a public Standard Load Balancer. Microsoft Default Rule Set 2.2 uses Block action; there are no custom rules or exclusions.

---

## 🧭 Architecture Overview

![Example 01 — Front Door Premium Prevention architecture](01_basic_prevention_policy_architecture.jpg)

*Figure 1. Front Door Premium with a Front Door Web Application Firewall Policy in Prevention mode (Microsoft DRS 2.2, Block action). HTTPS client traffic reaches the private NGINX backend over HTTP through a public Standard Load Balancer. The backend subnet is protected by an NSG, outbound connectivity uses a NAT Gateway, and Front Door diagnostics are sent to Log Analytics. The policy module owns only the Front Door policy; the pinned Front Door sibling owns delivery and its security association.*

| File | Responsibility |
|---|---|
| `resource_group.tf` | Dedicated lab Resource Group |
| `frontdoor_policy.tf` | Local Front Door policy module |
| `frontdoor.tf` | Front Door v0.1.0, origin, route, association and diagnostics |
| `networks.tf`, `nsg.tf` | VNet, private backend subnet and inbound boundary |
| `nat_gateway.tf` | Explicit backend outbound connectivity |
| `loadbalancers.tf` | Public frontend, backend pool and separate health probe |
| `compute.tf`, `cloud-init-nginx.yaml.tftpl` | Private VM and test application |
| `tls.tf` | Disposable lab SSH key; no private-key output |
| `log_analytics.tf` | Diagnostic workspace |
| `providers.tf`, `variables.tf`, `outputs.tf` | Provider and lab contracts |

| Flow | Boundary / expected behavior |
|---|---|
| Client → Front Door, HTTPS | Managed Front Door rules inspect requests before origin forwarding |
| Front Door → load balancer → NGINX, HTTP 80 | NSG permits `AzureFrontDoor.Backend`; NGINX requires this profile's `X-Azure-FDID` |
| Azure Load Balancer → VM, HTTP 8080 | NSG permits `AzureLoadBalancer`; probe does not require a Front Door header |
| VM → package repositories | NAT Gateway provides outbound connectivity |
| Internet client → origin IP, HTTP 80 | NSG denies direct application access |
| Operator → VM | Azure Run Command; no public VM IP or inbound SSH rule |

Port 8080 has no load-balancing rule and is not published to clients. Azure-provided DNS is used; there are no peerings, custom UDRs or private endpoints. Edge-to-origin HTTP is an educational simplification, not a production end-to-end TLS design.

Front Door backend addresses are shared across customers. The service tag alone is insufficient: the origin also checks the profile GUID, following [Microsoft's origin-security guidance](https://learn.microsoft.com/en-us/azure/frontdoor/origin-security).

---

## 🎯 Why this example exists

This lab demonstrates observable Prevention behavior rather than policy creation alone:

- A benign request reaches a real application.
- A controlled malicious request should be blocked at Front Door and recorded in diagnostics.
- The origin cannot be bypassed through its public load-balancer IP.
- The independently governed Front Door policy is attached by ID through a pinned sibling module.

This is neither an Application Gateway policy nor Azure Firewall. Infrastructure composition belongs only to the lab, not the root policy module.

---

## 🚀 Deployment Steps

```bash
cp terraform.tfvars.example terraform.tfvars
tofu fmt -check
tofu init
tofu validate
```

Set your subscription ID and a globally unique endpoint name. Authenticate externally; never put credentials in tfvars. The lab creates its own Resource Group and billable Front Door Premium, VM, load balancer, NAT Gateway and Log Analytics resources. Review availability and costs before deployment.

For a separately authorized deployment:

```bash
tofu apply -target=module.frontdoor_policy
tofu plan
tofu apply
```

The pinned Front Door v0.1.0 module calculates its association resource count from the policy ID. On a fresh deployment that ID is unknown, causing `Invalid count argument`. The one-time targeted policy bootstrap above resolves this; always follow it with a full apply. Targeting is an exceptional workaround, not the normal workflow for subsequent changes.

Allow time for Front Door propagation, cloud-init and origin health checks. The generated SSH private key is stored in Terraform state: protect state and use this key only for a disposable lab. No private key is committed or exposed as an output.

---

## 🖼️ Azure Portal View

Screenshots are planned evidence, not existing results. Collect them after deployment and redact subscription IDs and unrelated data.

| Planned screenshot | Evidence |
|---|---|
| `01_prevention_resource_group_overview.jpg` | Complete lab resources |
| `01_prevention_frontdoor_overview.jpg` | Premium profile and endpoint |
| `01_prevention_policy_overview.jpg` | Enabled Front Door policy, Prevention mode |
| `01_prevention_managed_rules.jpg` | Microsoft_DefaultRuleSet 2.2, Block action |
| `01_prevention_security_association.jpg` | Endpoint association and `/*` |
| `01_prevention_load_balancer.jpg` | Frontend, backend pool, port 80 rule and healthy port 8080 probe |
| `01_prevention_backend_network.jpg` | Private VM, NSG rules and NAT Gateway association |
| `01_prevention_diagnostic_settings.jpg` | Front Door logs sent to the lab workspace |
| `01_prevention_benign_request.jpg` | Successful HTTPS request and origin response header |
| `01_prevention_blocked_request.jpg` | Controlled request blocked at Front Door |
| `01_prevention_security_logs.jpg` | Matching block, URI and tracking reference |
| `01_prevention_origin_bypass.jpg` | Direct origin access denied |

Add image links and captions only after capturing the actual files.

---

## ✅ Test Results

Static verification on October 9, 2026 with OpenTofu 1.11.6 and AzureRM 4.81.0:

- `tofu fmt -check`: passed
- `tofu init -backend=false -no-color`: passed, including pinned sibling modules
- `tofu validate -no-color`: passed for the complete composition

Deployment was performed on October 9, 2026 with explicit approval: the policy bootstrap added 2 resources, then the full apply added 26 resources, with no changes or deletions. Azure accepted DRS 2.2 and created the Front Door association. The pinned sibling emitted a deprecation warning for its diagnostic `metric` block. Initial HTTPS health checks returned Front Door HTTP 404; application reachability and security enforcement are not yet verified. No screenshots have been collected.

After deployment:

1. Confirm cloud-init completed, NGINX is running and both health probes are healthy. Use Azure Run Command rather than opening inbound SSH.
2. Test the benign path:

   ```bash
   FRONTDOOR_HOST=$(tofu output -raw frontdoor_endpoint_host_name)
   curl -i "https://${FRONTDOOR_HOST}/health"
   curl -i "https://${FRONTDOOR_HOST}/search?lab=prevention-benign"
   ```

   Expect HTTP 200 and `X-FoggyKitchen-Origin: nginx-prevention-lab`.

3. Send a controlled XSS-like input to this disposable application only:

   ```bash
   curl -i --get \
     --data-urlencode 'search=<script>alert(1)</script>' \
     --data-urlencode 'lab=prevention-xss' \
     "https://${FRONTDOOR_HOST}/search"
   ```

   Expect a managed-rule block, normally HTTP 403, without the origin response header. The origin's `/search` handler otherwise returns a constant 200: it neither evaluates nor reflects the payload.

4. Correlate the request in the lab workspace:

   ```kusto
   AzureDiagnostics
   | where TimeGenerated > ago(1h)
   | where Category == "FrontDoorWebApplicationFirewallLog"
   | where requestUri_s contains "prevention-xss"
   | project TimeGenerated, action_s, ruleName_s, requestUri_s, trackingReference_s
   | order by TimeGenerated desc
   ```

   Confirm `Block` and the actual rule responsible. Logs can arrive after a delay. See [Microsoft's rule-tuning guidance](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-tuning?pivots=front-door-standard-premium). A 403 alone does not prove a managed Front Door rule blocked the request.

5. Inspect `/var/log/nginx/lab-access.log` through Azure Run Command. The benign marker should appear; the blocked marker should not. Confirm the accepted profile header matches `frontdoor_resource_guid`.
6. Test bypass from your Internet client:

   ```bash
   ORIGIN_IP=$(tofu output -raw origin_public_ip)
   curl -i --connect-timeout 10 --max-time 15 "http://${ORIGIN_IP}/health"
   ```

   Expect no successful HTTP response because the NSG denies your source. Locally on the VM, port 80 without `X-Azure-FDID` should return 403; the correct profile header should return 200. Port 8080 `/health` should remain healthy without that header.

7. Record actual statuses, rule matches, timestamps and screenshots here. Do not mark runtime checks passed until executed.

---

## 🧹 Cleanup

After recording evidence, review and destroy the isolated lab:

```bash
tofu destroy
```

This removes the lab Resource Group and its managed resources, including the association and policy. Do not reuse this lab's policy for external consumers without reviewing lifecycle coupling.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
