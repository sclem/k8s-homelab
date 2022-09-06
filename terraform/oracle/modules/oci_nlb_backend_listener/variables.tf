variable "healthcheck_protocol" {
  type    = string
  default = null
}

variable "healthcheck_port" {
  type    = string
  default = null
}

variable "protocol" {
  type    = string
  default = "TCP"
}

variable "listener_port" {
  type = string
}

variable "backend_port" {
  type = string
}

variable "network_load_balancer_id" {
  type = string
}

variable "target_id" {
  type    = string
  default = null
}

variable "ip_address" {
  type    = string
  default = null
}

variable "ipv6" {
  type    = bool
  default = false
}

variable "name" {
  type = string
}
