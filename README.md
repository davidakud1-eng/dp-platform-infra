# dp-platform-infra

Terraform configuration for the AWS infrastructure underneath the DP
platform: a VPC, three EC2 hosts, IAM roles scoped to what each host
actually needs, and an ephemeral Amazon EKS cluster.

This repository is one of three that make up the DP platform:

| Repository | Responsibility |
|---|---|
| `dp-platform-infra` (this repo) | AWS infrastructure (VPC, EC2, IAM, EKS) |
| [`dp-ansible`](../dp-ansible) | Host configuration, CI/CD toolchain, and cluster workloads |
| [`dp-mywebapp`](../dp-mywebapp) | The application deployed onto the platform |

For the full architecture picture — how this infrastructure relates to
what `dp-ansible` configures on top of it — see
[`dp-ansible/docs/architecture.md`](../dp-ansible/docs/architecture.md)
and [`dp-ansible/docs/network.md`](../dp-ansible/docs/network.md).

---

## What this provisions

- **Networking**: one VPC across two Availability Zones (`us-east-2a`,
  `us-east-2b`), each with a public and private subnet, a single NAT
  Gateway, and an Internet Gateway
- **Compute**: three EC2 instances (`jenkins-controller`, `build-agent`,
  `platform-ops`), IMDSv2-enforced, encrypted gp3 volumes
- **IAM**: two roles — a baseline role for Jenkins/build-agent, and a
  separately scoped role for `platform-ops` with least-privilege
  Terraform-execution and state-access policies (see
  [`dp-ansible/docs/architecture.md`](../dp-ansible/docs/architecture.md)
  §3 for the exact scoping)
- **EKS**: cluster, managed node group, the EBS CSI driver addon, the
  Pod Identity agent addon, and the IAM role/policy the AWS Load Balancer
  Controller authenticates with

---

## The `enable_eks_runtime` toggle

The EKS cluster, its node group, the NAT Gateway, its Elastic IP, and the
private route table only exist when `enable_eks_runtime = true` in
`terraform.tfvars`. When `false`, none of these resources are created —
deliberately, so this infrastructure doesn't accrue NAT Gateway and EKS
control-plane cost while it isn't actively in use.

This same variable is mirrored (under different names) across the
`dp-ansible` and `dp-mywebapp` pipelines — see
[`dp-ansible/docs/architecture.md`](../dp-ansible/docs/architecture.md)
§4 for the full table of where it's threaded through.

---

## Running this locally

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var="enable_eks_runtime=false"   # infra only, no EKS
terraform plan -var="enable_eks_runtime=true"    # includes EKS runtime
terraform apply <saved-plan-file>
```

State is stored remotely in S3 with native locking
(`use_lockfile = true` in `backend.tf`) — no DynamoDB lock table required.

In CI, this runs via the `Jenkinsfile` in this repo: format check → init
→ validate → plan (saved to a file) → display → conditional apply of
*that exact saved plan*, gated behind a separate `TERRAFORM_APPLY`
parameter so every push produces a reviewable plan without requiring it
to be applied. Full breakdown in
[`dp-ansible/docs/pipeline.md`](../dp-ansible/docs/pipeline.md) §3.

---

## State bucket bootstrap

Terraform's S3 backend cannot create its own backend bucket — the bucket
has to exist before `terraform init` can use it as one. This is a
one-time step, run manually outside of this repository, before Terraform
is ever run against it:

```bash
aws s3api create-bucket \
  --bucket dp-terraform-state-686953641182 \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

aws s3api put-bucket-versioning \
  --bucket dp-terraform-state-686953641182 \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket dp-terraform-state-686953641182 \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionRule":{"SSEAlgorithm":"AES256"}}]}'
```

Versioning is recommended so a bad `apply` or an accidental state
overwrite can be recovered from a previous object version rather than
being unrecoverable. Confirm the current status with:

```bash
aws s3api get-bucket-versioning --bucket dp-terraform-state-686953641182
```

**Everything after this one-time bootstrap is fully automated and
portable.** `backend.tf` declares the bucket, key, and region as code, so
`terraform init` on any authorized system — a laptop, a fresh clone, a CI
runner — wires up to the same remote state automatically, with no manual
reconfiguration per machine. Native S3 locking (`use_lockfile = true`)
prevents concurrent applies from corrupting state, and the committed
`.terraform.lock.hcl` pins every system to the same provider version.
The one thing that doesn't travel automatically is authorization — a
system needs AWS credentials equivalent to `platform_ops_role`'s scoped
policies to actually run Terraform here; the backend being automated
doesn't imply anyone with the code can apply changes.

---

## Known gaps

- **`alb.tf` is currently an empty placeholder.** There is no separately
  managed load balancer or TLS termination resource in this repo yet —
  ingress traffic reaches the cluster through the ALB that the AWS Load
  Balancer Controller provisions on demand from a Kubernetes Ingress
  resource, not through anything defined here.
- **`admin_ip` in `terraform.tfvars` is currently `0.0.0.0/0`.** This
  controls SSH, Jenkins UI, and Artifactory UI access on the security
  groups below. It's a named variable rather than a hardcoded value,
  which makes it a one-line fix, but it should be narrowed to a specific
  IP or CIDR before this is treated as anything beyond an active
  development target.
