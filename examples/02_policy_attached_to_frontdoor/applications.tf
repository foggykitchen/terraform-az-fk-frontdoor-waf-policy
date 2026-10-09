locals {
  # Stable keys keep profile, origin, VM and subnet ownership aligned.
  applications = {
    a = { endpoint_name = var.endpoint_names.a, subnet_prefix = "10.60.1.0/24" }
    b = { endpoint_name = var.endpoint_names.b, subnet_prefix = "10.60.2.0/24" }
  }
}
