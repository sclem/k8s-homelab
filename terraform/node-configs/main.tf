terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "node-configs/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

data "terraform_remote_state" "oci" {
  backend = "s3"

  config = {
    bucket                      = "terraform"
    key                         = "oracle/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

locals {
  oci_instances = data.terraform_remote_state.oci.outputs.instances
}

provider "kubernetes" {}

resource "kubernetes_labels" "oci-node" {
  for_each    = local.oci_instances
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = each.key
  }
  labels = {
    "failure-domain.beta.kubernetes.io/zone" = split(":", each.value.instance.availability_domain)[1]
  }
}

resource "kubernetes_annotations" "oci-node" {
  for_each    = local.oci_instances
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = each.key
  }
  annotations = {
    "oci.oraclecloud.com/compartment-id" = each.value.instance.compartment_id
  }
}
