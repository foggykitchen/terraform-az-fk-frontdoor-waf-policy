resource "tls_private_key" "ssh" {
  for_each  = local.applications
  algorithm = "RSA"
  rsa_bits  = 4096
}
