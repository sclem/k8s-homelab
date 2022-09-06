locals {
  lb_mapping = {
    https = {
      protocol = "TCP"
      port     = 443
      nodePort = 31443
    }
    http = {
      protocol = "TCP"
      port     = 80
      nodePort = 31080
    }
    stun = {
      protocol = "UDP"
      port     = 3478
      nodePort = 30478

      healthcheck_protocol = "TCP"
      healthcheck_port     = 31080
    }
  }
}

resource "oci_network_load_balancer_network_load_balancer" "main" {
  compartment_id                 = oci_identity_compartment.main.id
  display_name                   = "Homelab NLB"
  subnet_id                      = oci_core_subnet.lb.id
  freeform_tags                  = local.tags
  is_preserve_source_destination = false
  is_private                     = false
  network_security_group_ids     = [oci_core_network_security_group.internal.id, oci_core_network_security_group.lb.id]
  nlb_ip_version                 = "IPV4_AND_IPV6"
}

module "oci_nlb_backend_listener" {
  for_each = local.lb_mapping
  source   = "./modules/oci_nlb_backend_listener"

  name                     = "${each.key}-homelab-nlb"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  ipv6                     = false
  target_id                = module.k3s_node["oci-cloud-arm"].instance.id

  listener_port        = each.value.port
  backend_port         = each.value.nodePort
  protocol             = each.value.protocol
  healthcheck_port     = try(each.value.healthcheck_port, each.value.nodePort)
  healthcheck_protocol = try(each.value.healthcheck_protocol, each.value.protocol)
}

module "oci_nlb_backend_listener_v6" {
  for_each   = local.lb_mapping
  source     = "./modules/oci_nlb_backend_listener"
  depends_on = [module.oci_nlb_backend_listener]

  name                     = "${each.key}-homelab-nlb-v6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  ipv6                     = true
  ip_address               = module.k3s_node["oci-cloud-arm"].public_ipv6

  listener_port        = each.value.port
  backend_port         = each.value.nodePort
  protocol             = each.value.protocol
  healthcheck_port     = try(each.value.healthcheck_port, each.value.nodePort)
  healthcheck_protocol = try(each.value.healthcheck_protocol, each.value.protocol)
}

locals {
  lb_ipv4 = one([for data in oci_network_load_balancer_network_load_balancer.main.ip_addresses : data.ip_address if data.is_public && data.ip_version == "IPV4"])
  lb_ipv6 = one([for data in oci_network_load_balancer_network_load_balancer.main.ip_addresses : data.ip_address if data.is_public && data.ip_version == "IPV6"])
}

module "cloudflare_dualstack_dns_lb" {
  source = "./modules/cloudflare_dualstack_dns"

  zone         = var.cloudflare_zone_lb
  hostname     = var.lb_hostname
  ipv4_address = local.lb_ipv4
  ipv6_address = local.lb_ipv6
}
