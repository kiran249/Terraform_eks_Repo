# EKS on AWS with Terraform

Provisions a dev EKS cluster plus everything it needs:

| File | What it creates |
|------|-----------------|
| `versions.tf` | Terraform / provider version constraints |
| `backend.tf` | S3 remote state (`terraform-state-kiran-2026`, native S3 locking) |
| `provider.tf` | AWS provider with default tags on every resource |
| `locals.tf` | AZ lookup, subnet CIDRs derived from `vpc_cidr`, common tags |
| `variables.tf` / `terraform.tfvars` | Inputs and their values |
| `vpc.tf` | VPC, 2 public + 2 private subnets, single NAT gateway |
| `eks.tf` | EKS cluster, managed node group, add-ons, access entries |
| `bastion.tf` | Bastion EC2 host (kubectl, helm, kubeconfig preinstalled) |
| `outputs.tf` | Cluster, network and bastion outputs |
| `Jenkinsfile` | plan / apply / destroy pipeline |

## Prerequisites

- Terraform >= 1.10 (required for `use_lockfile` S3 locking)
- AWS credentials with permission to create VPC, EKS, EC2, IAM and KMS resources
- The S3 bucket `terraform-state-kiran-2026` must already exist in `us-east-1`

## Usage

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Configure kubectl (command is also printed as the `configure_kubectl` output)
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster

# SSH to the bastion
terraform output -raw bastion_ssh_private_key > bastion-key.pem
chmod 600 bastion-key.pem
$(terraform output -raw bastion_ssh_command)

# Tear everything down
terraform destroy
```

### Before `terraform destroy`

Delete any Kubernetes `LoadBalancer` Services and Ingresses first (for example
`kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer`).
Load balancers created by Kubernetes are not managed by Terraform and will block
deletion of the VPC subnets if left behind.

## Jenkins

The pipeline takes two parameters:

- `ACTION` – `plan`, `apply` or `destroy`. `destroy` builds a destroy plan (`plan -destroy`)
  and applies exactly that plan.
- `AUTO_APPROVE` – when unchecked, the pipeline pauses for manual approval after the plan.

It expects Jenkins credentials `aws-access-key-id` and `aws-secret-access-key`, and a
Windows agent (`bat` steps) with Terraform on the `PATH`.

## Notes

- `bastion_allowed_cidr` defaults to `0.0.0.0/0`; restrict it to your own IP.
- Kubernetes `1.33` leaves EKS standard support in mid-2026 and is then billed at the
  extended-support rate; bump `kubernetes_version` one minor version at a time to upgrade.
