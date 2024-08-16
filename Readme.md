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
