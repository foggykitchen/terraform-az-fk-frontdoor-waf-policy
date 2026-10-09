output "frontdoor_firewall_policy_id" {
  description = "Front Door policy ID for independent consumer attachment."
  value       = module.frontdoor_policy.frontdoor_firewall_policy_id
}
