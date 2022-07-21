output "configs" {
  sensitive = true
  value     = data.wireguard_config_document.conf
}
