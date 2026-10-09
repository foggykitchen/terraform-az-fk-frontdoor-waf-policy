variable "subscription_id" {
  description = "Azure subscription ID supplied externally; no credentials belong in this example."
  type        = string
}

variable "resource_group_name" {
  description = "Dedicated Resource Group created for the complete Prevention lab."
  type        = string
  default     = "fk-frontdoor-prevention-rg"
}

variable "name_prefix" {
  description = "Prefix for the lab's regional and Front Door resources."
  type        = string
  default     = "fk-fd-prevention"
}

variable "policy_name" {
  description = "Front Door policy name: alphanumeric, beginning with a letter."
  type        = string
  default     = "fkFrontDoorPrevention"
}

variable "endpoint_name" {
  description = "Globally unique Front Door endpoint name."
  type        = string
}

variable "location" {
  description = "Azure region hosting the backend and Log Analytics workspace."
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "IPv4 CIDR for the lab VNet."
  type        = string
  default     = "10.50.0.0/16"
}

variable "backend_subnet_prefix" {
  description = "Backend IPv4 subnet within the lab VNet."
  type        = string
  default     = "10.50.1.0/24"
}

variable "admin_username" {
  description = "VM administrator username; management uses Azure Run Command rather than inbound SSH."
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Size of the private NGINX VM."
  type        = string
  default     = "Standard_B1s"
}

variable "tags" {
  description = "Tags assigned to the complete Prevention lab."
  type        = map(string)
  default = {
    project = "foggykitchen"
    module  = "terraform-az-fk-frontdoor-waf-policy"
    example = "01_basic_prevention_policy"
    env     = "dev"
  }
}
