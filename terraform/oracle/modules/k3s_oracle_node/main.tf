data "template_cloudinit_config" "main" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = var.cloud_init_tpl
  }
}

resource "oci_core_instance" "main" {
  availability_domain                 = var.availability_domain
  compartment_id                      = var.compartment_id
  shape                               = "VM.Standard.A1.Flex"
  display_name                        = var.hostname
  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = var.tags

  shape_config {
    memory_in_gbs = var.ram
    ocpus         = var.cpus
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.main.rendered
  }

  source_details {
    source_id   = var.image_id
    source_type = "image"
  }

  availability_config {
    is_live_migration_preferred = true
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = var.subnet_id
    assign_private_dns_record = true
    hostname_label            = var.hostname
    private_ip                = var.private_ip
    nsg_ids                   = var.nsg_ids
    freeform_tags             = var.tags
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

data "oci_core_vnic_attachments" "main" {
  compartment_id = var.compartment_id

  instance_id = oci_core_instance.main.id
}

resource "oci_core_ipv6" "main" {
  vnic_id = data.oci_core_vnic_attachments.main.vnic_attachments[0].vnic_id

  freeform_tags = var.tags
}
