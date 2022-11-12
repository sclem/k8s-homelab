terraform {
  required_providers {
    mullvad = {
      source  = "ojford/mullvad"
      version = "~> 0.2.2"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.2.1+1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "mullvad/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "wireguard" {}

resource "wireguard_asymmetric_key" "wg" {}

provider "mullvad" {
  account_id = var.account_id
}

# set KUBE_CONFIG_PATH and KUBE_CTX
provider "kubernetes" {}

data "mullvad_city" "city" {
  name = var.city
}

data "mullvad_relay" "wg_relays" {
  filter {
    city_name    = var.city
    country_code = data.mullvad_city.city.country_code
    type         = "wireguard"
  }
}

resource "mullvad_wireguard" "peer" {
  public_key = wireguard_asymmetric_key.wg.public_key
}

resource "mullvad_port_forward" "wireguard" {
  country_code = data.mullvad_city.city.country_code
  city_code    = data.mullvad_city.city.city_code

  peer = mullvad_wireguard.peer.public_key
}

locals {
  servers = [for s in data.mullvad_relay.wg_relays.relays : s]
}

resource "random_integer" "num" {
  min = 0
  max = length(local.servers) - 1
  keepers = {
    val = wireguard_asymmetric_key.wg.public_key
  }
}

locals {
  peer = element(local.servers, random_integer.num.result)
}

data "wireguard_config_document" "doc" {
  private_key = wireguard_asymmetric_key.wg.private_key
  addresses = [
    mullvad_wireguard.peer.ipv4_address,
    mullvad_wireguard.peer.ipv6_address
  ]

  peer {
    endpoint             = "${local.peer.hostname}:51820"
    public_key           = local.peer.public_key
    allowed_ips          = ["0.0.0.0/0", "::0/0"]
    persistent_keepalive = 25
  }
}

resource "kubernetes_secret" "wg_conf" {
  metadata {
    namespace = "plex"
    name = "vpn-wg-conf"
  }

  data = {
    conf = data.wireguard_config_document.doc.conf
    forward-port = mullvad_port_forward.wireguard.port
  }
}
