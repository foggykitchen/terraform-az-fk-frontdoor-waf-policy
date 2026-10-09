module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "${var.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  address_space       = [var.vnet_address_space]
  subnets = {
    fk-prevention-backend = { address_prefixes = [var.backend_subnet_prefix] }
  }
  tags = var.tags
}
