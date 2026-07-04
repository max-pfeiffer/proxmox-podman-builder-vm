# Proxmox Podman Builder VM

OpenTofu configuration that provisions a virtual machine on a Proxmox VE hypervisor
whose sole purpose is to serve as a remote [Podman](https://podman.io) builder.
After applying, you can register the VM as a connection on your local machine and
run `podman build` there while the actual work happens on the VM.

The VM is fully provisioned by OpenTofu using the
[bpg/proxmox](https://registry.opentofu.org/providers/bpg/proxmox) provider:

- Downloads the Fedora Cloud base image onto the Proxmox node
- Creates the VM (4 cores, 16 GB RAM, 50 GB disk) with a static IP via cloud-init
- Creates a user with SSH key access
- Installs Podman and the QEMU guest agent
- Enables the rootless Podman API socket (`/run/user/1000/podman/podman.sock`),
  persistent across reboots via systemd lingering

Everything runs through the Proxmox API and SSH to the VM itself — no SSH access
to the Proxmox node is required. This is why the disk is created from the image
with the `import` content type (API-native) instead of cloud-init snippets, which
the provider can only upload over node SSH.

## Prerequisites

- [OpenTofu](https://opentofu.org) >= 1.8
- A Proxmox VE 8.2+ node
- A Proxmox API token with privileges to manage VMs and storage,
  e.g. `root@pam!opentofu` with privilege separation disabled
- The `import` content type enabled on the `local` storage
  (Datacenter → Storage → local → Content, or
  `pvesh set /storage/local --content backup,import,iso,vztmpl`)
- A **passphrase-less** SSH key pair for provisioning and the Podman connection:

  ```shell
  ssh-keygen -t ed25519 -N "" -f ~/.ssh/podman_builder_ed25519
  ```

  The `remote-exec` provisioner cannot decrypt passphrase-protected keys, so do
  not reuse your personal key here. Additional public keys (e.g. your personal
  one) can be authorized on the VM via `ssh_authorized_key_files`.

## Configuration

Copy the template
[configuration.auto.tfvars.example](configuration.auto.tfvars.example) and
adjust the values to your environment:

```shell
cp configuration.auto.tfvars.example configuration.auto.tfvars
```

`configuration.auto.tfvars` is git-ignored because it contains the API token.
The template covers all required variables: the Proxmox connection, the VM
network settings (`vm_vlan_id`, `vm_ip_address`, `vm_gateway`,
`vm_dns_servers`) and the SSH keys (`ssh_authorized_key_files`,
`ssh_private_key_file`).

All remaining settings are optional and have defaults, see
[variables.tf](variables.tf):

| Variable       | Default          | Description                       |
| -------------- | ---------------- | --------------------------------- |
| `vm_name`      | `podman-builder` | VM name in Proxmox                |
| `vm_id`        | `4020`           | Proxmox VM ID                     |
| `vm_cores`     | `4`              | CPU cores                         |
| `vm_memory`    | `16384`          | RAM in MB                         |
| `vm_disk_size` | `50`             | Disk size in GB                   |
| `vm_datastore` | `local-lvm`      | Datastore for disk and cloud-init |
| `vm_bridge`    | `vmbr0`          | Network bridge                    |
| `vm_username`  | `builder`        | User created on the VM            |

## Usage

Create the VM:

```shell
tofu init
tofu apply
```

The apply takes a few minutes: image download, VM boot, cloud-init and package
installation. On success, the `podman_connection_command` output contains the
ready-to-use command to register the remote builder locally:

```shell
podman system connection add remotebuilder \
  --identity ~/.ssh/podman_builder_ed25519 \
  ssh://<vm_username>@<vm_ip_address>/run/user/1000/podman/podman.sock
```

Then build on the VM from your local machine:

```shell
podman --connection remotebuilder build -t myimage .

# or make it the default connection for all podman commands
podman system connection default remotebuilder
```

Verify the connection with:

```shell
podman --connection remotebuilder version
```

Destroy the VM with `tofu destroy`. The registered connection can be removed
with `podman system connection remove remotebuilder`.
