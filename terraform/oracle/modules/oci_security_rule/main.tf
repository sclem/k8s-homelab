locals {
  tcp_options = var.tcp ? { "port" = var.port } : {}
  udp_options = !var.tcp ? { "port" = var.port } : {}
}

resource "oci_core_network_security_group_security_rule" "main" {
  for_each                  = toset(var.cidrs)
  network_security_group_id = var.network_security_group_id
  direction                 = "INGRESS"
  protocol                  = var.tcp ? "6" : "17"
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  dynamic "tcp_options" {
    for_each = local.tcp_options
    content {
      destination_port_range {
        min = tcp_options.value
        max = tcp_options.value
      }
    }
  }

  dynamic "udp_options" {
    for_each = local.udp_options
    content {
      destination_port_range {
        min = udp_options.value
        max = udp_options.value
      }
    }
  }

}
