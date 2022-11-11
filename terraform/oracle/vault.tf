resource "oci_kms_vault" "main" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = "K8s Vault"
  vault_type     = "DEFAULT"

  freeform_tags = local.tags
}

resource "oci_kms_key" "main" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = "K8s key"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  management_endpoint = oci_kms_vault.main.management_endpoint

  freeform_tags   = local.tags
  protection_mode = "HSM"
}
