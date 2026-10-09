output "resource_group_name" {
  description = "Dedicated lab Resource Group."
  value       = azurerm_resource_group.foggykitchen_rg.name
}
output "frontdoor_firewall_policy_id" {
  description = "The single Front Door policy ID consumed by both profiles."
  value       = module.frontdoor_policy.frontdoor_firewall_policy_id
}
output "applications" {
  description = "Application-specific test targets and Front Door associations, keyed a and b."
  value = {
    for key, app in local.applications : key => {
      endpoint_host_name = module.frontdoor[key].endpoint_host_name
      profile_id         = module.frontdoor[key].profile_id
      profile_name       = module.frontdoor[key].profile_name
      frontdoor_id       = module.frontdoor[key].resource_guid
      security_policy_id = module.frontdoor[key].security_policy_id
      origin_public_ip   = module.load_balancer[key].public_ip_address
      vm_name            = "${var.name_prefix}-${key}-nginx"
      vm_private_ip      = module.nginx[key].vm_private_ip
    }
  }
}
output "log_analytics_workspace_id" {
  description = "Log Analytics resource ID used by both Front Door diagnostic settings."
  value       = module.log_analytics.id
}
output "log_analytics_customer_id" {
  description = "Workspace GUID used by az monitor log-analytics query."
  value       = module.log_analytics.workspace_id
}
