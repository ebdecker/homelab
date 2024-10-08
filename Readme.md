# Homelab

Repo of current files and scripts used in my homelab setup.

## Packer

Packer lets you create identical machine images for multiple platforms from a single source configuration. A common use case is creating golden images for organizations to use in cloud infrastructure. [HashiCorp Packer Documentation](https://developer.hashicorp.com/packer/docs?ajs_aid=d6aa81ab-055d-469e-97ed-2f57626ada56&product_intent=packer)

Update credentials-example.pkr.hcl with vars for your environment.

Valite variables with template:
``` bash
packer validate -var-file='..\credentials.pkr.hcl' ubuntu-server-noble.pkr.hcl
```
Build template:
``` bash
packer build -var-file='..\credentials.pkr.hcl' ubuntu-server-noble.pkr.hcl
```
Note, any directories used in the template are relative to where the script is. For me, this was easiest to execute in the directory where the script was.

Not able to get template to work with username/password, only ssh. 

### References
- https://ronamosa.io/docs/engineer/LAB/proxmox-packer-vm/
- https://github.com/ChristianLempa/boilerplates/blob/main/packer/proxmox/ubuntu-server-jammy/http/user-data

---
## Terraform

Terraform is an infrastructure as code tool that lets you build, change, and version infrastructure safely and efficiently [Terraform Documentation](https://developer.hashicorp.com/terraform?ajs_aid=65c4757a-b701-49a9-95a7-d13ae24aee15&product_intent=terraform)

The current terraform is setup to bootstrap the initial Proxmox VMs for use in K3S HA architecture See here for architecture reference: https://docs.k3s.io/datastore/ha-embedded 

1 additional vm for installing and setting up a Rancher cluster.

Not currently managing state with this Terraform, but in the future could store state management on a drive somewhere on my Proxmox node.

You will need to supply the values in provider.tf with your own credentials.auto.tfvars file.

Init, plan, review, then apply
```bash
terraform init
# installs the telmate/proxmox and configures the local module and vars

terraform plan
## Review output of what Terraform will apply

terraform apply -auto-approve
### Will take several minutes to deploy multiple VMs. Review completed output
```

### VM Classes
Standard image is currently pulling a golden image from Proxmox that was setup via Packer. Currently ubunut-server-noble with 32GB HDD and mounting a cloudinit drive.

- Ella: 4 cpu cores. 4GB Memory
- Elliot: 6 cpu cores, 16GB Memory.

### References
- https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md
- https://github.com/ChristianLempa/boilerplates/blob/main/terraform/proxmox/full-clone.tf
- https://austinsnerdythings.com/2021/09/01/how-to-deploy-vms-in-proxmox-with-terraform/

---

## Ansible
Ansible provides open-source automation that reduces complexity and runs everywhere. Using Ansible lets you automate virtually any task. [Ansible Introduction](https://docs.ansible.com/ansible/latest/getting_started/introduction.html)


Currently, I have playbooks for basic bootstrap automation after my proxmox cluster and initial VMs are setup. These include
- docker setup
- apt update
- qemu guest agent install
- reboot
- reboot-required (check if system reboot is required)

Update the hosts file per your current environment.
To test connection with hosts:
```bash
ansible -i hosts servers -m ping --user serveradmin
```
Ansible commands must be ran on a machine with ssh keys already added to the target machine. If not using ssh keys, you could run a similar command with the password argument

I was going to add playbooks to boot strap the inital k3s-ha install and configuration but this linked repo does a much better job than I could do and it worked right out of the box [k3s-ansible on GitHub](https://github.com/techno-tim/k3s-ansible) Shoutout to Techno-Tim.

### References
- https://github.com/techno-tim/k3s-ansible
- https://github.com/techno-tim/k3s-ansible

---
