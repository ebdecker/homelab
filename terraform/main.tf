# Proxmox Full-Clone
# ---

module "ella_class_vms" {
  source = "./modules/proxmox_vms"

  vm_id_list = ["101", "102", "103", "107", "108"]
  vm_class_name = "pve-ella"
  vm_template_name = "ubuntu-server-noble"
  proxmox_node_name = "pve"
  vm_desc = "Ella class VM"
  vm_cpu_cores = 4
  vm_memory = 4096
  vm_serveradmin_password = var.serveradmin_password

}

module "elliot_class_vms" {
  source = "./modules/proxmox_vms"

  vm_id_list = ["104", "105", "106"]
  vm_class_name = "pve-elliot"
  vm_template_name = "ubuntu-server-noble"
  proxmox_node_name = "pve"
  vm_desc = "Elliot class VM"
  vm_cpu_cores = 6
  vm_memory = 16384
  vm_serveradmin_password = var.serveradmin_password

}