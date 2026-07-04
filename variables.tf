variable "endpoint" {
  type = string
}

variable "api_token" {
  type      = string
  sensitive = true
}

variable "node_name" {
  type = string
}

variable "vm_name" {
  type    = string
  default = "podman-builder"
}

variable "vm_id" {
  type    = number
  default = 4020
}

variable "vm_cores" {
  type    = number
  default = 4
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 16384
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "vm_datastore" {
  type    = string
  default = "local-lvm"
}

variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_vlan_id" {
  description = "Optional VLAN tag for the network device, no VLAN tag is set by default"
  type        = number
  default     = null
}

variable "vm_ip_address" {
  description = "IPv4 address in CIDR notation"
  type        = string
}

variable "vm_gateway" {
  type = string
}

variable "vm_dns_servers" {
  type = list(string)
}

variable "vm_username" {
  type    = string
  default = "builder"
}

variable "ssh_authorized_key_files" {
  description = "Public keys granted SSH access to the VM user"
  type        = list(string)
}

variable "ssh_private_key_file" {
  description = "Passphrase-less private key used by the remote-exec provisioner and the podman connection"
  type        = string
}
