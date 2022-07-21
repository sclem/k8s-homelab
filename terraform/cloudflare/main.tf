terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "cloudflare/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "cloudflare" {}

//data "cloudflare_zone" "zone" {
//  name = var.zone
//}
//
//resource "cloudflare_access_application" "plex" {
//  zone_id                   = data.cloudflare_zone.zone.id
//  name                      = "plex"
//  domain                    = "plex.${data.cloudflare_zone.zone.name}"
//  type                      = "self_hosted"
//  session_duration          = "24h"
//  auto_redirect_to_identity = false
//}
//
//resource "cloudflare_access_group" "plex" {
//  zone_id = data.cloudflare_zone.zone.id
//  name    = "plex public whitelist"
//
//  include {
//    ip = var.ip_whitelist
//  }
//}
//
//resource "cloudflare_access_policy" "plex" {
//  application_id = cloudflare_access_application.plex.id
//  zone_id        = cloudflare_access_application.plex.zone_id
//  name           = "plex public policy"
//  precedence     = "1"
//  decision       = "bypass"
//
//  include {
//    group = [cloudflare_access_group.plex.id]
//  }
//}
//
//output "data" {
//  value = cloudflare_access_policy.plex
//}

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "dns_token" {
  name = "k8s-dns-token"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.*" = "*"
    }
  }
}

resource "kubernetes_namespace" "external_dns_namespace" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_secret" "cloudflare_dns_token" {
  metadata {
    namespace = "external-dns"
    name      = "cloudflare-token"
  }

  data = {
    token = cloudflare_api_token.dns_token.value
  }
}
