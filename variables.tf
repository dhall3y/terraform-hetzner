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

variable "peer_device_id" {
  description = "syncthing device id of the peer to connect to"
  type        = string
}

variable "peer_name" {
  description = "name of the peer"
  type        = string
}

variable "peer_ip" {
  description = "ip of the peer running syncthing"
  type        = string
}

variable "peer_port" {
  description = "peer syncthing listening port"
  type        = string
}

variable "peer_folder_id" {
  description = "id of the peer folder to sync"
  type        = string
}

variable "peer_folder_label" {
  description = "label of the peer folder to sync"
  type        = string
}
