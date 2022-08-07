terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.87.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

