variable "port" {
  type    = number
  default = 51820
}

variable "peers" {
  type = list(object({
    fqdn = string
    wan  = bool # if true, don't set endpoint on this nodes's peers
  }))
  default = []
}

variable "wg_cidr" {
  type    = string
  default = "192.168.100.0/24"
}

variable "pod_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
