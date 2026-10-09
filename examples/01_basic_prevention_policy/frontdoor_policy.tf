module "frontdoor_policy" {
  source = "../.."

  name                = var.policy_name
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  sku_name            = "Premium_AzureFrontDoor"
  policy_settings     = { mode = "Prevention" }
  managed_rule_sets   = [{ type = "Microsoft_DefaultRuleSet", version = "2.2", action = "Block" }]
  tags                = var.tags
}
