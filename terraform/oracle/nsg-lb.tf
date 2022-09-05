resource "oci_core_network_security_group" "lb" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab-lb"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group_security_rule" "lb-ingress-tcp-http" {
  for_each                  = local.everywhere_cidrs
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "INGRESS"
  protocol                  = "6" # tcp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb-ingress-tcp-https" {
  for_each                  = local.everywhere_cidrs
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "INGRESS"
  protocol                  = "6" # tcp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb-ingress-udp-stun" {
  for_each                  = local.everywhere_cidrs
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "INGRESS"
  protocol                  = "17" # udp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 3478
      max = 3478
    }
  }
}
