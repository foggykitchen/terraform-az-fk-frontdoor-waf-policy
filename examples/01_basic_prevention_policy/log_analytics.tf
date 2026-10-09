module "log_analytics" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-log-analytics.git?ref=v1.0.0"

  name                = "${var.name_prefix}-logs"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  retention_in_days   = 30
  tags                = var.tags
}
