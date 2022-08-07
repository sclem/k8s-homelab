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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.20.0"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "oracle/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
