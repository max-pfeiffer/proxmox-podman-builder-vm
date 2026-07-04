locals {
  vm_ip = split("/", var.vm_ip_address)[0]
}

# Installs Podman and exposes its rootless API socket. Runs over SSH against
# the VM because the bpg provider would need SSH access to the Proxmox node
# itself to upload cloud-init user-data snippets.
resource "terraform_data" "podman_provisioning" {
  triggers_replace = [proxmox_virtual_environment_vm.podman_builder.id]

  connection {
    type        = "ssh"
    host        = local.vm_ip
    user        = var.vm_username
    private_key = file(pathexpand(var.ssh_private_key_file))
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo cloud-init status --wait || true",
      "sudo dnf install -y -q podman qemu-guest-agent",
      "sudo systemctl --global enable podman.socket",
      "sudo loginctl enable-linger ${var.vm_username}",
      "sudo systemctl restart user@$(id -u).service",
      "sleep 3",
      "XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user enable --now podman.socket",
      "XDG_RUNTIME_DIR=/run/user/$(id -u) systemctl --user is-active podman.socket",
      "podman --version",
    ]
  }
}
