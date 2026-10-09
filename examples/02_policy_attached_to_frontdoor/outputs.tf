output "frontdoor_firewall_policy_id" {
  description = "Front Door policy ID for independent consumer attachment."
  value       = module.frontdoor_policy.frontdoor_firewall_policy_id
}

output "security_policy_id" {
  description = "Sibling-owned Front Door security-policy association ID."
  value       = module.frontdoor.security_policy_id
}

output "endpoint_host_name" {
  description = "Hostname of the protected Front Door endpoint."
  value       = module.frontdoor.endpoint_host_name
}
