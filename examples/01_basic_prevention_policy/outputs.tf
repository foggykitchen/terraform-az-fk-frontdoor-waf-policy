output "frontdoor_firewall_policy_id" {
  description = "Front Door policy ID attached to the lab profile."
  value       = module.frontdoor_policy.frontdoor_firewall_policy_id
}

output "frontdoor_endpoint_host_name" {
  description = "Hostname used for end-to-end HTTP tests."
  value       = module.frontdoor.endpoint_host_name
}

output "frontdoor_profile_id" {
  description = "Front Door profile resource ID for Azure inspection and diagnostics."
  value       = module.frontdoor.profile_id
}

output "frontdoor_resource_guid" {
  description = "Expected X-Azure-FDID checked by NGINX."
  value       = module.frontdoor.resource_guid
}

output "security_policy_id" {
  description = "Sibling-owned policy association ID."
  value       = module.frontdoor.security_policy_id
}

output "resource_group_name" {
  description = "Dedicated Resource Group created for the lab."
  value       = azurerm_resource_group.foggykitchen_rg.name
}

output "nginx_vm_name" {
  description = "Private NGINX VM name for Azure Run Command."
  value       = "${var.name_prefix}-nginx"
}

output "nginx_private_ip" {
  description = "Private IP of the NGINX VM."
  value       = module.nginx.vm_private_ip
}

output "origin_public_ip" {
  description = "Load Balancer frontend; direct Internet application access is denied."
  value       = module.load_balancer.public_ip_address
}

output "log_analytics_workspace_id" {
  description = "Log Analytics customer ID for querying Front Door diagnostics."
  value       = module.log_analytics.workspace_id
}

output "log_analytics_resource_id" {
  description = "Log Analytics workspace Azure resource ID."
  value       = module.log_analytics.id
}
