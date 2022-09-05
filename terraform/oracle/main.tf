locals {
  tags = {
    project = "homelab"
  }
  vcn_cidr = "10.123.0.0/16"

  everywhere_cidrs = toset([
    "::/0",
    "0.0.0.0/0"
  ])
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

  dynamic "route_rules" {
    for_each = local.everywhere_cidrs
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_internet_gateway.main.id
    }
  }
}

// default sg for egress
resource "oci_core_security_list" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-default-egress-all"
  freeform_tags  = local.tags

  dynamic "egress_security_rules" {
    for_each = local.everywhere_cidrs
    content {
      protocol    = "all"
      destination = egress_security_rules.value
    }
  }
}

resource "oci_core_subnet" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = cidrsubnet(module.vcn.vcn_all_attributes.cidr_blocks[0], 8, 0)
  ipv6cidr_block = cidrsubnet(module.vcn.vcn_all_attributes.ipv6cidr_blocks[0], 8, 0)
  freeform_tags  = local.tags

  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]

  display_name = "public-subnet"
  dns_label    = "public"
}

resource "oci_core_subnet" "lb" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = cidrsubnet(module.vcn.vcn_all_attributes.cidr_blocks[0], 8, 1)
  ipv6cidr_block = cidrsubnet(module.vcn.vcn_all_attributes.ipv6cidr_blocks[0], 8, 1)
  freeform_tags  = local.tags

  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]

  display_name = "public-subnet-lb"
  dns_label    = "publiclb"
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
  nsg_ids             = [oci_core_network_security_group.internal.id, oci_core_network_security_group.instance.id]
  availability_domain = each.value.az

  tags = local.tags
}

module "cloudflare_dualstack_dns" {
  source   = "./modules/cloudflare_dualstack_dns"
  for_each = module.k3s_node

  zone         = var.cloudflare_zone
  hostname     = each.value.instance.hostname_label
  ipv4_address = each.value.public_ipv4
  ipv6_address = each.value.public_ipv6
}
