variable "cloud_init_tpl" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "hostname" {
  type = string
}

variable "tags" {
  type    = object({})
  default = {}
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "image_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "ram" {
  type = number
}

variable "cpus" {
  type = number
}

variable "nsg_ids" {
  type = list(string)
}

variable "compartment_id" {
  type = string
}
