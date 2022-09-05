resource "oci_core_network_security_group" "instance" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab-instance"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group_security_rule" "instance-ipv6-ingress-udp-wg51820" {
  for_each                  = local.everywhere_cidrs
  network_security_group_id = oci_core_network_security_group.instance.id
  direction                 = "INGRESS"
  protocol                  = "17" # udp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 51820
      max = 51821
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-ingress-udp-wg41820" {
  for_each                  = local.everywhere_cidrs
  network_security_group_id = oci_core_network_security_group.instance.id
  direction                 = "INGRESS"
  protocol                  = "17" # udp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 41820
      max = 41820
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance-ipv4-ingress-tcp-ssh" {
  for_each                  = toset([for cidr in local.everywhere_cidrs : cidr if var.enable_ssh])
  network_security_group_id = oci_core_network_security_group.instance.id
  direction                 = "INGRESS"
  protocol                  = "6" # tcp
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
