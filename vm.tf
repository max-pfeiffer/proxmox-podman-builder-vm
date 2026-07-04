# Fedora ships a Podman 5.x server matching current Podman clients. The
# "import" content type allows disk creation from the image through the
# Proxmox API alone; the "iso" content type would require SSH access to
# the node.
resource "proxmox_download_file" "fedora_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
  file_name    = "Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
}

resource "proxmox_virtual_environment_vm" "podman_builder" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.node_name
  description = "Podman remote builder, managed by OpenTofu"
  tags        = ["opentofu", "podman"]

  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  stop_on_destroy = true

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory
  }

  agent {
    # qemu-guest-agent is installed by the provisioner in provisioning.tf.
    # Enabling it here would make the provider wait for the agent during VM
    # creation, before the provisioner has had a chance to install it.
    enabled = false
  }

  disk {
    datastore_id = var.vm_datastore
    import_from  = proxmox_download_file.fedora_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    iothread     = true
    size         = var.vm_disk_size
  }

  network_device {
    bridge  = var.vm_bridge
    vlan_id = var.vm_vlan_id
  }

  serial_device {}

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.vm_dns_servers
    }

    user_account {
      username = var.vm_username
      keys     = [for f in var.ssh_authorized_key_files : trimspace(file(pathexpand(f)))]
    }
  }
}
