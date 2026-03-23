# AWS Two-Tier VPC Architecture with Terraform Modules

The same AWS two-tier architecture as [dashboard-counting-app](../dashboard-counting-app/README.md) — rebuilt using community Terraform modules instead of hand-written resources. Built as a learning exercise to understand the tradeoffs between writing infrastructure from scratch vs leveraging pre-built modules.

> **Recommended reading order**: Do the from-scratch version first. Modules make much more sense when you already know what resources they're creating underneath.

---

## Architecture Overview

![Architecture Diagram](assets/dash-count.png)

## Working Demo

https://github.com/user-attachments/assets/81cbc011-c7f8-417a-9aa0-1465383f8e5f

Same architecture as the from-scratch version — different Terraform approach.

---

## Modules Used

| Module                                   | Version  | Replaces                                                                  |
| ---------------------------------------- | -------- | ------------------------------------------------------------------------- |
| `terraform-aws-modules/vpc/aws`          | `~> 5.0` | `vpc.tf` + `igw.tf` + `subnets.tf` + `nat-gateway.tf` + `route-tables.tf` |
| `terraform-aws-modules/ec2-instance/aws` | `~> 5.0` | `bastion.tf` + `app-server.tf`                                            |

These are the most downloaded Terraform modules on the registry, maintained by the `terraform-aws-modules` community and used in production by thousands of teams.

---

## What Was Learned

### The Core Mental Model Shift

Modules are functions. From-scratch is writing the function body. Modules are calling someone else's well-tested function:

```hcl
# FROM SCRATCH — you write every resource explicitly
resource "aws_vpc" "main" { ... }
resource "aws_internet_gateway" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_subnet" "private" { ... }
resource "aws_eip" "nat" { ... }
resource "aws_nat_gateway" "main" { ... }
resource "aws_route_table" "public" { ... }
resource "aws_route_table" "private" { ... }
resource "aws_route_table_association" "public" { ... }
resource "aws_route_table_association" "private" { ... }

# WITH MODULES — one call replaces all of the above
module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "~> 5.0"
  cidr               = "10.0.0.0/16"
  azs                = ["us-west-1a", "us-west-1c"]
  public_subnets     = ["10.0.10.0/24"]
  private_subnets    = ["10.0.130.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}
```

### How Modules Reference Each Other

Direct resource references become module output references:

```hcl
# FROM SCRATCH               → WITH MODULES
aws_vpc.main.id              → module.vpc.vpc_id
aws_subnet.public.id         → module.vpc.public_subnets[0]
aws_subnet.private.id        → module.vpc.private_subnets[0]
aws_eip.nat.public_ip        → module.vpc.nat_public_ips[0]
aws_instance.bastion.public_ip  → module.bastion.public_ip
aws_instance.bastion.private_ip → module.bastion.private_ip
aws_instance.app_server.private_ip → module.app_server.private_ip
```

The `[0]` index on VPC outputs is because the module always returns lists — even with one subnet. EC2 module outputs are single values because each call represents one instance.

### Why Variables Use Lists Instead of Single Strings

```hcl
# FROM SCRATCH — single values
public_az  = "us-west-1a"
private_az = "us-west-1c"

# WITH MODULES — lists (matches what the VPC module expects)
azs                  = ["us-west-1a", "us-west-1c"]
public_subnet_cidrs  = ["10.0.10.0/24"]
private_subnet_cidrs = ["10.0.130.0/24"]
```

Lists make scaling trivial. Adding a second AZ pair later is just appending to the list — no code structure changes needed.

### How `enable_nat_gateway` Knows Where to Put the NAT

Nothing extra needed — the module infers placement from three arguments together:

```hcl
public_subnets     = ["10.0.10.0/24"]  # defines where public subnets are
enable_nat_gateway = true              # tells module to create NAT
single_nat_gateway = true              # place in first public subnet
```

Internally the module runs the same logic you'd write by hand:

```hcl
# What the module does internally (simplified)
resource "aws_nat_gateway" "this" {
  subnet_id     = aws_subnet.public[0].id  # always first public subnet
  allocation_id = aws_eip.nat[0].id
  depends_on    = [aws_internet_gateway.this]
}
```

### `single_nat_gateway` — Cost vs Resilience Tradeoff

```
single_nat_gateway = true   (learning / dev)
├── one NAT gateway in first public subnet
├── all private subnets share it
├── ~$0.045/hr flat
└── if that AZ goes down, private subnets lose internet

single_nat_gateway = false  (production)
├── one NAT gateway per AZ
├── each private subnet has its own NAT
├── ~$0.045/hr × number of AZs
└── fully fault tolerant
```

### `terraform state list` — Seeing Through the Abstraction

After `terraform apply`, this command shows every real AWS resource the modules created:

```bash
terraform state list
```

Output shows the module namespace:

```
module.vpc.aws_vpc.this[0]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.private[0]
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_eip.nat[0]
module.vpc.aws_nat_gateway.this[0]
module.vpc.aws_route_table.public[0]
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.private[0]
module.bastion.aws_instance.this[0]
module.app_server.aws_instance.this[0]
```

Every resource from the from-scratch version is present — just namespaced under `module.*`. The module didn't skip anything, it organized it.

### What Modules Don't Abstract

Some resources are still written as raw `resource` blocks because no module is needed or the customization required would be more complex than just writing the resource directly:

- `aws_security_group` — the rules are specific to this architecture
- `tls_private_key` + `aws_key_pair` + `local_file` — key generation is straightforward
- `data "aws_ami"` — a single data source lookup needs no module wrapper

Understanding which things to put in modules and which to leave as raw resources is a key Terraform skill.

---

## File Structure

```
dashboard-counting-app-module/
├── versions.tf       # Provider versions — identical to from-scratch
├── variables.tf      # Input declarations — lists instead of single AZ strings
├── terraform.tfvars  # Actual values — gitignored, never commit
├── main.tf           # All three module calls (vpc + bastion + app_server)
├── security-group.tf # Raw resources — vpc_id refs module.vpc.vpc_id
├── ssh-key.tf        # Identical to from-scratch
├── data.tf           # Identical to from-scratch
└── outputs.tf        # Module output references instead of resource refs
```

**From scratch vs modules — file count:**

```
FROM SCRATCH    WITH MODULES
────────────────────────────
14 files        8 files
~300 lines      ~180 lines
```

---

## From Scratch vs Modules — Full Comparison

| Aspect                    | From Scratch             | With Modules                   |
| ------------------------- | ------------------------ | ------------------------------ |
| Files                     | 14                       | 8                              |
| Lines of HCL              | ~300                     | ~180                           |
| Every resource visible    | ✅ yes                   | ❌ hidden inside module        |
| Control over exact config | ✅ full                  | ⚠️ limited to module inputs    |
| Speed to write            | slow                     | fast                           |
| Understanding required    | must know AWS resources  | can use without deep knowledge |
| Debugging                 | straightforward          | need `terraform state list`    |
| Best for                  | learning, unique configs | teams, standard patterns       |
| Scaling to multi-AZ       | requires code changes    | add item to list               |

Neither is strictly better. From scratch is better for learning and unusual architectures. Modules are better for speed, consistency, and standard patterns in team environments.

---

## Prerequisites

- Terraform `>= 1.0` — [install](https://developer.hashicorp.com/terraform/install)
- AWS CLI configured with a named profile
- IAM user needs: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`

```bash
# Set your AWS profile
export AWS_PROFILE=your-profile-name

# Verify credentials
aws sts get-caller-identity
```

---

## Configuration

Edit `terraform.tfvars`:

```hcl
aws_region   = "us-west-1"
project_name = "dashboard-counting"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.10.0/24"]
private_subnet_cidrs = ["10.0.130.0/24"]
azs                  = ["us-west-1a", "us-west-1c"]

my_ip         = "YOUR.IP.HERE/32"
instance_type = "t2.micro"
key_name      = "dashboard-counting-key"
```

| Variable               | Type         | Description                           |
| ---------------------- | ------------ | ------------------------------------- |
| `aws_region`           | string       | AWS region                            |
| `project_name`         | string       | Prefix for all resource names         |
| `vpc_cidr`             | string       | VPC CIDR block                        |
| `public_subnet_cidrs`  | list(string) | Public subnet CIDRs                   |
| `private_subnet_cidrs` | list(string) | Private subnet CIDRs                  |
| `azs`                  | list(string) | Availability zones                    |
| `my_ip`                | string       | Your IP for SSH access (`x.x.x.x/32`) |
| `instance_type`        | string       | EC2 instance type                     |
| `key_name`             | string       | SSH key pair name                     |

> ⚠️ **`us-west-1` only has `us-west-1a` and `us-west-1c`** — `us-west-1b` does not exist.

---

## Deploy

```bash
# Download all three modules (vpc + ec2-instance × 2)
terraform init

# Preview — ~20 resources to add
terraform plan

# Build everything
terraform apply

# Print connection details
terraform output
```

Expected output:

```
app_server_private_ip = "10.0.130.x"
bastion_private_ip    = "10.0.10.x"
bastion_public_ip     = "3.101.x.x"
nat_gateway_public_ip = "52.8.x.x"
vpc_id                = "vpc-0xxxxxxxxx"
ssh_to_bastion        = "ssh -i dashboard-counting-key.pem -A ec2-user@3.101.x.x"
ssh_to_app_server     = "ssh ec2-user@10.0.130.x"
dashboard_url         = "http://3.101.x.x:9000"
```

---

## Connecting to Servers

```bash
# Load key into SSH agent (required for agent forwarding)
ssh-add dashboard-counting-key.pem

# SSH into bastion
ssh -i dashboard-counting-key.pem -A ec2-user@<bastion-public-ip>

# From inside bastion — SSH into app server
ssh ec2-user@<app-server-private-ip>
```

---

## Services

| Service   | Host                 | Port | Binary                          |
| --------- | -------------------- | ---- | ------------------------------- |
| Dashboard | Bastion (public)     | 9000 | `dashboard-service_linux_amd64` |
| Counting  | App server (private) | 9001 | `counting-service_linux_amd64`  |

Both services start automatically via `user_data` on instance launch. If they need to be started manually:

**On bastion:**

```bash
nohup env PORT=9000 COUNTING_SERVICE_URL="http://<app-server-private-ip>:9001" \
  ./dashboard-service_linux_amd64 > ~/dashboard-service.log 2>&1 &
```

**On app server:**

```bash
nohup env PORT=9001 ./counting-service_linux_amd64 > ~/counting-service.log 2>&1 &
```

**Verify running:**

```bash
ps aux | grep dashboard-service
sudo ss -tlnp | grep 9000
cat ~/dashboard-service.log
```

---

## Useful Debugging Commands

```bash
# See every real AWS resource the modules created
terraform state list

# Inspect a specific module's state
terraform state show module.vpc.aws_nat_gateway.this[0]
terraform state show module.bastion.aws_instance.this[0]

# Re-print outputs without re-applying
terraform output

# Check a specific output
terraform output bastion_public_ip
terraform output ssh_to_bastion
```

---

## Security Notes

- Bastion SSH restricted to `my_ip` only (`/32` CIDR)
- App server has no public IP — unreachable from internet
- App server SG only accepts traffic from bastion SG (identity-based)
- Private key stored in `terraform.tfstate` in plaintext — never commit state files
- For production: use AWS Secrets Manager or HashiCorp Vault

---

## Teardown

```bash
terraform destroy
```

> ⚠️ **NAT Gateway bills ~$0.045/hr even when idle.** Always destroy when done with a lab. NAT gateways cannot be stopped — only destroyed.

---

## Lessons from Debugging

| Error                                         | Cause                                  | Fix                                |
| --------------------------------------------- | -------------------------------------- | ---------------------------------- |
| `No valid credential sources found`           | Wrong or missing AWS profile           | `export AWS_PROFILE=your-profile`  |
| `availabilityZone us-west-1b is invalid`      | `us-west-1b` doesn't exist             | Use `us-west-1c`                   |
| `nohup: failed to run command 'PORT=9000'`    | `nohup` doesn't handle inline env vars | Use `nohup env PORT=9000 ./binary` |
| `Permission denied (publickey)` on app server | SSH agent not loaded                   | `ssh-add key.pem` before SSHing    |
| `/var/log/x.log: Permission denied`           | `/var/log` owned by root               | Write logs to `~/` instead         |

---

## Resources

- [terraform-aws-modules/vpc source code](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-aws-modules/ec2-instance source code](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance)
- [Terraform Module Registry](https://registry.terraform.io)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [hashicorp/demo-consul-101](https://github.com/hashicorp/demo-consul-101)
