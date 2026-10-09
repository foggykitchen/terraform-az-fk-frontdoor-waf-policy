variable "subscription_id" {
  description = "Azure subscription ID supplied externally; no credentials belong in this example."
  type        = string
}

variable "resource_group_name" {
  description = "Existing Resource Group for the Front Door policy and profile."
  type        = string
}

variable "policy_name" {
  description = "Front Door policy name: alphanumeric, beginning with a letter."
  type        = string
  default     = "fkFrontDoorShared"
}

variable "tags" {
  description = "Tags assigned to example resources."
  type        = map(string)
  default     = { project = "foggykitchen", env = "dev" }
}

variable "frontdoor_name" {
  description = "Name of the consuming Front Door Premium profile."
  type        = string
  default     = "fk-shared-frontdoor"
}

variable "endpoint_name" {
  description = "Globally unique Front Door endpoint name."
  type        = string
}

variable "origin_host_name" {
  description = "Existing HTTPS origin hostname with a valid matching TLS certificate."
  type        = string
}
