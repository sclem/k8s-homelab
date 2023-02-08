resource "oci_core_network_security_group" "lb" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab-lb"
  freeform_tags  = local.tags
}

module "nlb_security_rule" {
  source   = "./modules/oci_security_rule"
  for_each = local.lb_mapping

  network_security_group_id = oci_core_network_security_group.lb.id
  tcp                       = each.value.protocol == "TCP"
  cidrs                     = local.everywhere_cidrs
  port                      = each.value.port
}
