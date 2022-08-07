locals {
  tags = {
    project = "homelab"
  }
  vcn_cidr = "10.123.0.0/16"
}

provider "oci" {
  config_file_profile = var.config_file_profile
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "oci_identity_compartment" "main" {
  compartment_id = var.tenancy_ocid
  description    = "Cloud Free Tier"
  name           = "homelab"
  freeform_tags  = local.tags
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.5.0"

  compartment_id = oci_identity_compartment.main.id
  vcn_name       = oci_identity_compartment.main.name
  vcn_dns_label  = oci_identity_compartment.main.name

  create_internet_gateway = false
  create_nat_gateway      = false
  create_service_gateway  = false
  enable_ipv6             = true
  vcn_cidrs               = [local.vcn_cidr]

  freeform_tags = local.tags
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  enabled        = true
  display_name   = "internet-gateway"
}

resource "oci_core_route_table" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

output "vpc" {
  value = module.vcn
}

resource "oci_core_security_list" "ssh" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-ssh"
  freeform_tags  = local.tags

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "SSH traffic"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "SSH traffic"

    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_security_list" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-public"
  freeform_tags  = local.tags

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  egress_security_rules {
    stateless        = false
    destination      = "::/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "http"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "http"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "https"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "https"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17"
    description = "wireguard k8s"

    udp_options {
      min = 41820
      max = 41820
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17"
    description = "wireguard k8s"

    udp_options {
      min = 41820
      max = 41820
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17"
    description = "wireguard k8s"

    udp_options {
      min = 51820
      max = 51821
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17"
    description = "wireguard k8s"

    udp_options {
      min = 51820
      max = 51821
    }
  }
}

resource "oci_core_network_security_group" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab"
  freeform_tags  = local.tags
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.main.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.main.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_subnet" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = cidrsubnet(module.vcn.vcn_all_attributes.cidr_blocks[0], 8, 0)
  ipv6cidr_block = cidrsubnet(module.vcn.vcn_all_attributes.ipv6cidr_blocks[0], 8, 0)
  freeform_tags  = local.tags

  route_table_id = oci_core_route_table.main.id
  security_list_ids = concat([
    oci_core_security_list.main.id,
  ], var.enable_ssh ? [oci_core_security_list.ssh.id] : [])

  display_name = "public-subnet"
  dns_label    = "public"
}

resource "oci_core_subnet" "secondary" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = cidrsubnet(module.vcn.vcn_all_attributes.cidr_blocks[0], 8, 1)
  ipv6cidr_block = cidrsubnet(module.vcn.vcn_all_attributes.ipv6cidr_blocks[0], 8, 1)
  freeform_tags  = local.tags

  route_table_id = oci_core_route_table.main.id
  security_list_ids = concat([
    oci_core_security_list.main.id,
  ], var.enable_ssh ? [oci_core_security_list.ssh.id] : [])

  display_name = "public-subnet-2"
  dns_label    = "public2"
}

output "subnets" {
  value = {
    main      = oci_core_subnet.main
    secondary = oci_core_subnet.secondary
  }
}

data "oci_identity_availability_domains" "main" {
  #Required
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id = oci_identity_compartment.main.id

  state                    = "AVAILABLE"
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_id_arm = element([for img in data.oci_core_images.ubuntu.images : img if can(regex("aarch64", img.display_name))], 0)
}

module "k3s_node" {
  source = "./modules/k3s_oracle_node"
  for_each = {
    # this is dependent on wg_k8s hostname and cloudflare zone
    "oci-cloud-arm" : {
      private_ip = cidrhost(oci_core_subnet.main.cidr_block, 100)
      az         = element(data.oci_identity_availability_domains.main.availability_domains, 0).name
    }
  }

  compartment_id = oci_identity_compartment.main.id

  image_id       = local.image_id_arm.id
  ssh_public_key = file(var.ssh_public_key_path)
  cloud_init_tpl = templatefile("cloud-init.yaml", {
    default_user = var.username
  })

  ram  = 24
  cpus = 4

  hostname            = each.key
  private_ip          = each.value.private_ip
  subnet_id           = oci_core_subnet.main.id
  nsg_ids             = [oci_core_network_security_group.main.id]
  availability_domain = each.value.az

  tags = local.tags
}

output "instances" {
  value = module.k3s_node
}

module "cloudflare_dualstack_dns" {
  source   = "./modules/cloudflare_dualstack_dns"
  for_each = module.k3s_node

  zone         = var.cloudflare_zone
  hostname     = each.value.instance.hostname_label
  ipv4_address = each.value.public_ipv4
  ipv6_address = each.value.public_ipv6
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
