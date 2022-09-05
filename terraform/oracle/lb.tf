locals {
  lb_mapping = {
    "31443" = {
      protocol = "TCP"
      name     = "https"
      port     = 443
    }
    "31080" = {
      protocol = "TCP"
      name     = "http"
      port     = 80
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

resource "oci_network_load_balancer_backend_set" "this" {
  for_each = local.lb_mapping
  health_checker {
    protocol = each.value.protocol
    port     = each.key
  }
  name                     = "backend-homelab-nlb-${each.value.name}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV4"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend_set" "this-v6" {
  for_each = local.lb_mapping
  health_checker {
    protocol = each.value.protocol
    port     = each.key
  }
  name                     = "backend-homelab-nlb-v6-${each.value.name}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV6"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_listener" "this" {
  for_each                 = oci_network_load_balancer_backend_set.this
  default_backend_set_name = each.value.name
  name                     = "listener-${each.value.name}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = local.lb_mapping[each.value.health_checker[0].port].port
  protocol                 = local.lb_mapping[each.value.health_checker[0].port].protocol
  ip_version               = "IPV4"
}

resource "oci_network_load_balancer_listener" "this-v6" {
  for_each                 = oci_network_load_balancer_backend_set.this-v6
  default_backend_set_name = each.value.name
  name                     = "listener-v6-${each.value.name}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = local.lb_mapping[each.value.health_checker[0].port].port
  protocol                 = local.lb_mapping[each.value.health_checker[0].port].protocol
  ip_version               = "IPV6"
}

resource "oci_network_load_balancer_backend" "this" {
  for_each = oci_network_load_balancer_backend_set.this

  backend_set_name         = each.value.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = each.value.health_checker[0].port

  name      = "backend-${each.value.name}"
  target_id = module.k3s_node["oci-cloud-arm"].instance.id
}

resource "oci_network_load_balancer_backend" "this-v6" {
  depends_on = [oci_network_load_balancer_backend.this]
  for_each   = oci_network_load_balancer_backend_set.this-v6

  backend_set_name         = each.value.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = each.value.health_checker[0].port

  name = "backend-v6-${each.value.name}"
  //target_id  = module.k3s_node["oci-cloud-arm"].instance.id
  ip_address = module.k3s_node["oci-cloud-arm"].public_ipv6
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
