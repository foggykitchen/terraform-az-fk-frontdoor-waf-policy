variable "subscription_id" {
  description = "Azure subscription ID supplied externally; no credentials belong in this example."
  type        = string
}

variable "resource_group_name" {
  description = "Dedicated Resource Group created for the complete Detection tuning lab."
  type        = string
  default     = "fk-frontdoor-tuning-rg"
}

variable "name_prefix" {
  description = "Prefix for the lab's regional and Front Door resources."
  type        = string
  default     = "fk-fd-tuning"
}

variable "policy_name" {
  description = "Front Door policy name: alphanumeric, beginning with a letter."
  type        = string
  default     = "fkFrontDoorTuning"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,127}$", var.policy_name))
    error_message = "policy_name must be alphanumeric and begin with a letter."
  }
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
  default     = "10.70.0.0/16"
}

variable "backend_subnet_prefix" {
  description = "Backend IPv4 subnet within the lab VNet."
  type        = string
  default     = "10.70.1.0/24"
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
  description = "Tags assigned to the complete Detection tuning lab."
  type        = map(string)
  default = {
    project = "foggykitchen"
    module  = "terraform-az-fk-frontdoor-waf-policy"
    example = "03_detection_mode_with_custom_rules"
    env     = "dev"
  }
}

variable "policy_mode" {
  description = "Detection by default; change to Prevention only after reviewing runtime evidence and approving enforcement."
  type        = string
  default     = "Detection"
  validation {
    condition     = contains(["Detection", "Prevention"], var.policy_mode)
    error_message = "policy_mode must be Detection or Prevention."
  }
}

variable "approved_client_cidrs" {
  description = "Approved admin socket IP CIDRs. Supply actual reviewed client ranges before enforcing Prevention."
  type        = list(string)
  validation {
    condition     = length(var.approved_client_cidrs) > 0 && alltrue([for cidr in var.approved_client_cidrs : can(cidrhost(cidr, 0))])
    error_message = "approved_client_cidrs must contain at least one valid CIDR."
  }
}

variable "login_rate_threshold" {
  description = "Login requests per socket IP during the rate window; edge counters are approximate."
  type        = number
  default     = 200
  validation {
    condition     = var.login_rate_threshold >= 1 && floor(var.login_rate_threshold) == var.login_rate_threshold
    error_message = "login_rate_threshold must be a positive integer."
  }
}

variable "login_rate_duration_minutes" {
  description = "Front Door login rate-limit window in minutes."
  type        = number
  default     = 5
  validation {
    condition     = contains([1, 5], var.login_rate_duration_minutes)
    error_message = "login_rate_duration_minutes must be 1 or 5."
  }
}
