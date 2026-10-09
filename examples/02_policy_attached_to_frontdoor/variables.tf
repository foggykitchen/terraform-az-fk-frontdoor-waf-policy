variable "subscription_id" {
  description = "Azure subscription ID supplied externally; no credentials belong in this example."
  type        = string
}
variable "resource_group_name" {
  description = "Dedicated Resource Group created for both applications and the shared Front Door policy."
  type        = string
  default     = "fk-frontdoor-shared-rg"
}
variable "name_prefix" {
  description = "Prefix for the lab resources."
  type        = string
  default     = "fk-fd-shared"
}
variable "policy_name" {
  description = "Alphanumeric Front Door policy name, beginning with a letter."
  type        = string
  default     = "fkFrontDoorShared"
}
variable "endpoint_names" {
  description = "Two distinct, globally unique Front Door endpoint names, keyed a and b."
  type        = object({ a = string, b = string })
  validation {
    condition     = trimspace(var.endpoint_names.a) != "" && trimspace(var.endpoint_names.b) != "" && lower(var.endpoint_names.a) != lower(var.endpoint_names.b)
    error_message = "Provide two nonempty, distinct endpoint names."
  }
}
variable "location" {
  description = "Azure region hosting both applications and Log Analytics."
  type        = string
  default     = "westeurope"
}
variable "vnet_address_space" {
  description = "Fixed isolated lab VNet; application subnets are 10.60.1.0/24 and 10.60.2.0/24."
  type        = string
  default     = "10.60.0.0/16"
  validation {
    condition     = var.vnet_address_space == "10.60.0.0/16"
    error_message = "This lab uses the documented fixed 10.60.0.0/16 address plan."
  }
}
variable "admin_username" {
  description = "VM administrator; management uses Azure Run Command, not inbound SSH."
  type        = string
  default     = "azureuser"
}
variable "vm_size" {
  description = "Size of each private NGINX VM."
  type        = string
  default     = "Standard_B1s"
}
variable "tags" {
  description = "Tags assigned to the shared Front Door policy lab."
  type        = map(string)
  default = {
    project = "foggykitchen"
    module  = "terraform-az-fk-frontdoor-waf-policy"
    example = "02_policy_attached_to_frontdoor"
    env     = "dev"
  }
}
