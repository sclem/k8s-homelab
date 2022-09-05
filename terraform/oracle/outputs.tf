output "instances" {
  value = module.k3s_node
}

output "lb" {
  value = oci_network_load_balancer_network_load_balancer.main
}

data "terraform_remote_state" "wg_k8s" {
  backend = "s3"

  config = {
    bucket                      = "terraform"
    key                         = "wg-k8s-nodes/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

locals {
  node_ips = {
    primary = {
      for k, v in module.k3s_node : k => split("/", element(tolist(data.terraform_remote_state.wg_k8s.outputs.configs["${k}.${var.cloudflare_zone}"].addresses), 0))[0]
    }
    without_cidr = {
      for k, v in module.k3s_node : k => join(",", [for addr in data.terraform_remote_state.wg_k8s.outputs.configs["${k}.clem.stream"].addresses : split("/", addr)[0]])
    }
  }
  k3sup_args = {
    for k, v in module.k3s_node : k => "--user ${var.username} --server-ip 192.168.100.1 --ip ${local.node_ips.primary[k]} --k3s-version v1.23.7+k3s1 --k3s-extra-args '--node-ip=${local.node_ips.without_cidr[k]} --node-external-ip=${v.public_ipv4},${v.public_ipv6} --node-taint cloud=oracle:NoExecute --node-label cloud=oracle'"
  }
}

output "args" {
  value = local.k3sup_args
}

output "buckets" {
  value = oci_objectstorage_bucket.this
}

output "vpc" {
  value = module.vcn
}

output "subnets" {
  value = {
    main = oci_core_subnet.main
    lb   = oci_core_subnet.lb
  }
}
