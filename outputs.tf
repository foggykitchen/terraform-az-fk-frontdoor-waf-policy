output "frontdoor_firewall_policy_id" {
  description = "The ID of the Azure Front Door Web Application Firewall Policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.id
}

output "frontdoor_firewall_policy_name" {
  description = "The name of the Azure Front Door Web Application Firewall Policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.name
}

output "frontdoor_firewall_policy_sku_name" {
  description = "The SKU of the Azure Front Door Web Application Firewall Policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.sku_name
}
