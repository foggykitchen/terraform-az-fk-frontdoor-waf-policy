module "backend_nsg" {
  for_each = local.applications
  source   = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "${var.name_prefix}-${each.key}-backend-nsg"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  rules = [
    {
      name                       = "AllowFrontDoorHttp"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "AzureFrontDoor.Backend"
      destination_address_prefix = each.value.subnet_prefix
      description                = "Only Front Door backend traffic reaches the application listener."
    },
    {
      name                       = "AllowLoadBalancerProbe"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = each.value.subnet_prefix
      description                = "Dedicated health listener for Azure Load Balancer probes."
    },
    {
      name                       = "DenyOtherInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = each.value.subnet_prefix
      description                = "Prevent direct Internet and default VNet inbound access, including SSH."
    }
  ]
  subnet_associations = {
    backend = { subnet_id = module.vnet.subnet_ids["fk-shared-${each.key}-backend"] }
  }
  tags = var.tags
}
