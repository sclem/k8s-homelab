resource "oci_core_network_security_group" "instance" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab-instance"
  freeform_tags  = local.tags
}

locals {
  exposed_instance_ports = {
    wg51820 = {
      port     = 51820
      protocol = "UDP"
    }
    wg41820 = {
      port     = 41820
      protocol = "UDP"
    }
    stun = {
      port     = 30478
      protocol = "UDP"
    }
    relay = {
      port     = 30883
      protocol = "TCP"
    }
  }
  instance_ports = var.enable_ssh ? merge({ ssh = { port = 22, protocol = "TCP" } }, local.exposed_instance_ports) : local.exposed_instance_ports
}

module "instance_security_rule" {
  source   = "./modules/oci_security_rule"
  for_each = local.instance_ports

  network_security_group_id = oci_core_network_security_group.instance.id
  tcp                       = each.value.protocol == "TCP"
  cidrs                     = local.everywhere_cidrs
  port                      = each.value.port
}
