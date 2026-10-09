module "nginx" {
  for_each = local.applications
  source   = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "${var.name_prefix}-${each.key}-nginx"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  deployment_mode     = "vm"
  subnet_id           = module.vnet.subnet_ids["fk-shared-${each.key}-backend"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh[each.key].public_key_openssh
  vm_size             = var.vm_size
  lb_attachment       = { backend_pool_id = module.load_balancer[each.key].backend_pool_id }
  custom_data = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {
    frontdoor_id = module.frontdoor[each.key].resource_guid
    application  = upper(each.key)
  }))
  tags = var.tags

  depends_on = [module.backend_nsg, module.nat_gateway]
}
