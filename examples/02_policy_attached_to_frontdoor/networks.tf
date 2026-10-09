module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "${var.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  address_space       = [var.vnet_address_space]
  subnets = {
    for key, app in local.applications : key => { address_prefixes = [app.subnet_prefix] }
  }
  tags = var.tags
}
