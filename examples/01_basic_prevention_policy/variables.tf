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
  default     = "fkFrontDoorPrevention"
}

variable "tags" {
  description = "Tags assigned to example resources."
  type        = map(string)
  default     = { project = "foggykitchen", env = "dev" }
}
