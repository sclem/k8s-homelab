variable "ip_whitelist" {
  default = []
  type    = list(string)
}

variable "zone" {
  default = ""
  type    = string
}
