output "instance" {
  value = oci_core_instance.main
}

output "public_ipv4" {
  value = oci_core_instance.main.public_ip
}

output "public_ipv6" {
  value = oci_core_ipv6.main.ip_address
}
