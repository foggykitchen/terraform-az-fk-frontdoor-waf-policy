module "nginx" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "${var.name_prefix}-nginx"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  deployment_mode     = "vm"
  subnet_id           = module.vnet.subnet_ids["fk-tuning-backend"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh.public_key_openssh
  vm_size             = var.vm_size
  lb_attachment       = { backend_pool_id = module.load_balancer.backend_pool_id }
  custom_data = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {
    frontdoor_id = module.frontdoor.resource_guid
  }))
  tags = var.tags

  depends_on = [module.backend_nsg, module.nat_gateway]
}
