variable "hcloud_token" {
  description = "hetzner token"
  sensitive   = true
  type        = string
}

variable "wg_endpoint" {
  description = "wireguard endpoint address"
  type        = string
}

variable "wg_port" {
  description = "wireguard endpoint port"
  type        = number
}

variable "wg_private_key" {
  description = "wireguard private key"
  type        = string
  sensitive   = true
}

variable "wg_address" {
  description = "attributed ip when connected"
  type        = string
}
