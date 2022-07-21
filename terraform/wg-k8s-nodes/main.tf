terraform {
  required_providers {
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.2.1+1"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "wg-k8s-nodes/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

resource "wireguard_asymmetric_key" "wg" {
  for_each = toset(var.peers.*.fqdn)
}

locals {
  peer_list = {
    for i, p in var.peers : p.fqdn => merge(p, {
      wg_ips      = ["${cidrhost(var.wg_cidr, i + 1)}/32"]
      key         = wireguard_asymmetric_key.wg[p.fqdn]
      allowed_ips = [cidrsubnet(var.pod_cidr, 8, i)]
    })
  }

  peer_list_peers = {
    for k, v in local.peer_list : k => merge(local.peer_list[k], {
      peers = { for host in setsubtract(var.peers.*.fqdn, [k]) : host => local.peer_list[host] }
    })
  }
}

output "test" {
  sensitive = true
  value     = local.peer_list_peers
}

data "wireguard_config_document" "conf" {
  for_each = local.peer_list_peers

  private_key = each.value.key.private_key
  addresses   = each.value.wg_ips
  listen_port = var.port

  dynamic "peer" {
    for_each = each.value.peers
    content {
      endpoint             = each.value.wan ? "" : "${peer.key}:${var.port}"
      public_key           = peer.value.key.public_key
      allowed_ips          = concat(peer.value.wg_ips, peer.value.allowed_ips)
      persistent_keepalive = 25
    }
  }
}
