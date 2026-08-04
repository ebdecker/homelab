# Homelab Repository Guidance

## Architecture

This repository manages a layered homelab platform:

`Proxmox VE -> Packer -> Terraform -> Ansible -> K3s HA -> Fleet GitOps`

- Packer builds the `ubuntu-server-noble` Proxmox template.
- Terraform provisions Proxmox VMs from that template.
- Ansible bootstraps the hosts.
- K3s runs three control-plane nodes and two agent nodes with embedded etcd.
- Fleet deploys Helm charts and raw Kubernetes manifests from `charts/`.

## Repository Map

- `packer/`: Proxmox Ubuntu template creation.
- `terraform/`: VM provisioning.
- `terraform/modules/proxmox_vms/`: Reusable Proxmox VM module.
- `ansible/hosts`: Current inventory and VM addresses.
- `ansible/playbooks/`: Host bootstrap playbooks.
- `charts/*/fleet.yaml`: Fleet deployment definitions.
- `charts/*/values.yaml`: Helm values.
- `charts/*/overlays/dev/`: Kustomize resources such as ingress and monitoring.
- `k8s/misc/`: Manually managed certificates, issuers, and external ingress.
- `docs/specs/`: Monitoring and alerting specifications.

## Infrastructure

### VM classes

- Ella: 4 CPU cores and 4 GB RAM. VM IDs 101-104.
- Elliot: 6 CPU cores and 16 GB RAM. VM ID 120.
- VM 104 overrides its defaults with a 232 GB root disk and a 1.2 TB
  `k8s-dir-storage` disk.
- VM 120 overrides its root disk to 232 GB and passes through USB device
  `1a86:55d4`.

The Terraform module merges `class_defaults` with per-VM overrides. Optional
`virtio2` disks and USB devices are emitted through dynamic blocks.

### Terraform constraints

- Use the `telmate/proxmox` provider pinned by the repository.
- Use `try(...)` for potentially absent nested attributes; do not assume boolean
  expressions safely guard all nested attribute access.
- Set provider disk attributes such as `format` and `replicate` explicitly when
  needed to prevent persistent drift.
- Preserve Terraform resource addresses. If an addressing change is required,
  describe the corresponding `terraform state mv` migration.
- Never commit Terraform state, credentials, `.tfvars`, or generated provider
  files.
- Do not run `terraform apply` unless the user explicitly requests a live
  infrastructure change.

## Fleet and Kubernetes Conventions

For a new application:

1. Create `charts/<app>/`.
2. Add `fleet.yaml` with its namespace and pinned Helm chart version, or raw
   manifests for a non-Helm workload.
3. Add `values.yaml` for Helm configuration.
4. Add `overlays/dev/` when the application needs ingress or extra resources.
5. Include every overlay resource in its `kustomization.yaml`.

Fleet deploys repository changes after merge. Do not run mutating `kubectl`
commands against the live cluster unless explicitly requested. Prefer manifest
changes and read-only diagnostic commands.

### Monitoring

- Monitoring resources live under
  `charts/kube-prometheus-stack/overlays/dev/`.
- Custom alerts use a `GitOps` prefix, such as
  `GitOpsLonghornVolumeFault`.
- PrometheusRule resources require the repository's discovery labels.
- Alertmanager receivers reference Kubernetes Secrets; never commit webhook
  URLs or other secret values.
- Longhorn backup state `3` means completed and state `4` means error for
  Longhorn v1.3.0 and later.
- Confirm a metric exists and is scraped before adding an alert based on it.

## Local Service Context

- Internal domain: `moria-lab.com`.
- Traefik LoadBalancer address: `192.168.10.35`.
- TLS is managed by cert-manager using Cloudflare DNS challenges.
- Main namespaces include `traefik-system`, `monitoring`, `longhorn-system`,
  `ha`, `zigbee`, `zwave`, `mqtt`, and `homarr`.

Treat addresses, storage names, node assignments, USB IDs, and domain names as
environment-specific. Preserve them unless the requested change concerns that
environment configuration.

## Validation

Run validation relevant to the files changed. Prefer checks that do not require
live infrastructure or credentials.

```bash
# Packer, from packer/ubuntu-server-noble
packer validate -var-file='../credentials.pkr.hcl' ubuntu-server-noble.pkr.hcl

# Terraform, from terraform/
terraform fmt -check -recursive
terraform validate
terraform plan

# Ansible, from ansible/
ansible-playbook -i hosts playbooks/<playbook>.yml --syntax-check

# Kustomize overlay
kubectl kustomize charts/<app>/overlays/dev
```

`terraform plan` and Packer validation may require local credentials or
initialized providers. If unavailable, report which validation was skipped.

Useful read-only cluster diagnostics include:

```bash
kubectl get pods --all-namespaces
kubectl get deployments --all-namespaces
kubectl get services --all-namespaces
kubectl get nodes
kubectl get pvc --all-namespaces
kubectl get ingressroute --all-namespaces
kubectl get prometheusrule --all-namespaces
kubectl get alertmanagerconfig --all-namespaces
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Pull Requests

Use conventional commit-style PR titles:

- `feat:` new applications or capabilities
- `fix:` corrections
- `chore:` upgrades and maintenance
- `docs:` documentation
- `refactor:` restructuring without intended behavior changes

PR bodies should contain:

- `## Summary`: what changed and why.
- `## Changes`: affected paths and concise descriptions.
- `## Technical Details`: only for migrations, breaking changes, or complex
  implementation details.
- `## References`: relevant upstream documentation or issues.
- `## Testing`: validation performed and post-merge Fleet checks.

Do not claim live-cluster verification unless it was actually performed.

## Safety and Repository Hygiene

- Never commit credentials, tokens, webhook URLs, kubeconfigs, state, or private
  keys.
- Preserve unrelated working-tree changes.
- Inspect current manifests instead of relying solely on version summaries in
  documentation, which may lag the deployed Fleet configuration.
- Ask before making destructive infrastructure or cluster changes.
- Keep application versions pinned and update associated syntax, CRDs, and
  monitoring configuration together when an upgrade requires it.
