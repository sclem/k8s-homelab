variable "network_security_group_id" {
  type        = string
  description = "The OCID of the network security group."
}

variable "tcp" {
  type        = bool
  default     = true
  description = "Whether to use TCP or UDP."
}

variable "cidrs" {
  type        = list(string)
  description = "The source CIDR block or IP address range."
}

variable "port" {
  type        = number
  description = "The port"
}
