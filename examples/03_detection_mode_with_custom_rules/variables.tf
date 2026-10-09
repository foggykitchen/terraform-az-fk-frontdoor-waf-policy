variable "subscription_id" {
  description = "Azure subscription ID supplied externally; no credentials belong in this example."
  type        = string
}

variable "resource_group_name" {
  description = "Existing Resource Group for the Front Door policy."
  type        = string
}

variable "policy_name" {
  description = "Front Door policy name: alphanumeric, beginning with a letter."
  type        = string
  default     = "fkFrontDoorTuning"
}

variable "tags" {
  description = "Tags assigned to example resources."
  type        = map(string)
  default     = { project = "foggykitchen", env = "dev" }
}

variable "approved_client_cidrs" {
  description = "Approved admin client CIDRs; documentation-only default must be replaced before enforcement."
  type        = list(string)
  default     = ["192.0.2.0/24"]
}
