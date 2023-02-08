data "oci_objectstorage_namespace" "this" {
  compartment_id = oci_identity_compartment.main.id
}

resource "oci_objectstorage_bucket" "this" {
  for_each       = toset(var.bucket_names)
  compartment_id = oci_identity_compartment.main.id
  name           = each.key
  namespace      = data.oci_objectstorage_namespace.this.namespace

  access_type           = "NoPublicAccess"
  auto_tiering          = "InfrequentAccess"
  versioning            = "Disabled"
  object_events_enabled = false

  freeform_tags = local.tags
}
