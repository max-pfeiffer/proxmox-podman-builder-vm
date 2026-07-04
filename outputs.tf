output "vm_ip_address" {
  value = local.vm_ip
}

output "podman_connection_command" {
  description = "Registers the VM as a remote builder on your local machine"
  value       = "podman system connection add remotebuilder --identity ${var.ssh_private_key_file} ssh://${var.vm_username}@${local.vm_ip}/run/user/1000/podman/podman.sock"
}
