# packer-debian
Debian templates built with Packer for Proxmox. Remember to add file `variables.pkrvars.hcl` into the root of this repo.
The file should contain: 
```text
proxmox_api_url = "your-proxmox-host"
proxmox_api_token_id = "your-token-id"
proxmox_api_token_secret = "your-secret"

proxmox_node = "your-proxmox-node"
```
