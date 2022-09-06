resource "oci_network_load_balancer_backend_set" "this" {
  //for_each = local.lb_mapping
  health_checker {
    protocol = coalesce(var.healthcheck_protocol, var.protocol)
    port     = coalesce(var.healthcheck_port, var.backend_port)
  }
  name                     = "backendset-${var.name}"
  network_load_balancer_id = var.network_load_balancer_id
  policy                   = "FIVE_TUPLE"
  ip_version               = var.ipv6 ? "IPV6" : "IPV4"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_listener" "this" {
  default_backend_set_name = oci_network_load_balancer_backend_set.this.name
  name                     = "listener-${var.name}"
  network_load_balancer_id = var.network_load_balancer_id
  port                     = var.listener_port
  protocol                 = var.protocol
  ip_version               = var.ipv6 ? "IPV6" : "IPV4"
}

resource "oci_network_load_balancer_backend" "this" {
  backend_set_name         = oci_network_load_balancer_backend_set.this.name
  network_load_balancer_id = var.network_load_balancer_id
  port                     = var.backend_port

  name       = "backend-${var.name}"
  target_id  = var.target_id
  ip_address = var.ip_address
}
