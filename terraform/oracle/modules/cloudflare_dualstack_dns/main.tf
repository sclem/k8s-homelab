data "cloudflare_zone" "main" {
  name = var.zone
}

resource "cloudflare_record" "main" {
  for_each = { "A" : var.ipv4_address, "AAAA" : var.ipv6_address }
  zone_id  = data.cloudflare_zone.main.id
  name     = var.hostname
  type     = each.key
  value    = each.value
}
