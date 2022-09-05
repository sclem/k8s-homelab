// allow inter-vpc traffic
resource "oci_core_network_security_group" "internal" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab-internal"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group_security_rule" "internal-ingress" {
  network_security_group_id = oci_core_network_security_group.internal.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.internal.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_network_security_group_security_rule" "internal-egress" {
  network_security_group_id = oci_core_network_security_group.internal.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.internal.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}
