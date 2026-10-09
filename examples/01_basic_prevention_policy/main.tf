module "frontdoor_policy" {
  source = "../.."

  name                = var.policy_name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags
}
