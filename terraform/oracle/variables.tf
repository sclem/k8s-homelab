variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "username" {
  type = string
}

variable "cloudflare_zone" {
  type = string
}

variable "config_file_profile" {
  type    = string
  default = "DEFAULT"
}

variable "cloudflare_api_token" {
  type = string
}

variable "enable_ssh" {
  type    = bool
  default = false
}
