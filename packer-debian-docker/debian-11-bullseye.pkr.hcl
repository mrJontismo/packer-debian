# Initialize variables
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "memory" {
  type = string
  default = "4096"
}

variable "cores" {
  type = string
  default = "2"
}

variable "disk_size" {
  type = string
  default = "20G"
}

source "proxmox-iso" "debian-11" {
  # Proxmox connection settings
  proxmox_url = var.proxmox_api_url
  username = var.proxmox_api_token_id
  token = var.proxmox_api_token_secret

  # Skip TLS verification
  insecure_skip_tls_verify = true

  # VM network adapter configuration
  network_adapters {
    bridge = "vmbr0"
    model = "virtio"
    firewall = "false"
  }

  # VM disk configuration
  disks {
    disk_size = var.disk_size
    format = "qcow2"
    storage_pool = "local"
    storage_pool_type = "directory"
    type = "virtio"
  }

  # Settings for ISO file
  iso_file = "local:iso/debian-11.6.0-amd64-netinst.iso"
  iso_storage_pool = "local"
  unmount_iso = true

  # HTTP server configuration
  http_directory = "http"
  boot_wait = "10s"

  # Debian preseed
  boot_command = ["<esc><wait>auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]

  # Cloud Init configuration
  cloud_init = true
  cloud_init_storage_pool = "local"

  # General settings
  template_description = "Debian 11 cloud-init template. Built on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  vm_name = "debian-11.6-docker"
  node = var.proxmox_node
  scsi_controller = "virtio-scsi-single"
  memory = var.memory
  cores = var.cores
  sockets = "1"
  qemu_agent = true

  # SSH connection settings for provisioning
  # Root will get a new, random password later on, so no need to change that
  ssh_username = "root"
  ssh_password = "packer"
}

build {
  sources = ["source.proxmox-iso.debian-11"]

  # Moving cloud-config over to the VM
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source = "http/cloud.cfg"
  }

   # Installing docker
    provisioner "shell" {
        inline = [
            "apt install -y apt-transport-https ca-certificates curl gnupg lsb-release",
            "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
            "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "apt update",
            "apt install -y docker-ce docker-ce-cli containerd.io docker-compose"
        ]
    }
}
