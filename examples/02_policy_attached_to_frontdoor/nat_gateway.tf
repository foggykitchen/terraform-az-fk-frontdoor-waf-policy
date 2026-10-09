module "nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = "${var.name_prefix}-natgw"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  public_ip_name      = "${var.name_prefix}-natgw-pip"
  subnet_associations = {
    for key, app in local.applications : key => { subnet_id = module.vnet.subnet_ids["fk-shared-${key}-backend"] }
  }
  tags = var.tags
}
