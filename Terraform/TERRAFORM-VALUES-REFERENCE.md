# Terraform – What Values to Update

Use this as a checklist. Values are set in **two places**: (1) **terraform.tfvars** for variables, (2) **main.tf** for the backend bucket (one-time edit).

---

## 1. Values you must set (terraform.tfvars)

Create `Terraform/environments/test/terraform.tfvars` (copy from `terraform.tfvars.example`) and set:

| Variable       | Where to set        | Example / description                    |
|----------------|---------------------|------------------------------------------|
| **project_id** | `terraform.tfvars`  | Your GCP project ID, e.g. `my-project-123` |
| **region**     | `terraform.tfvars`   | GCP region for GKE/VPC, e.g. `us-central1` |
| **environment**| `terraform.tfvars`   | Environment name: `dev`, `test`, or `prod` (default: `dev`) |

**Example `terraform.tfvars`:**

```hcl
project_id  = "my-gcp-project-id"
region      = "us-central1"
environment = "dev"
```

Do **not** commit `terraform.tfvars` if it contains real project IDs (it’s in `.gitignore`).

---

## 2. Backend bucket (one-time edit in main.tf)

**File:** `Terraform/environments/test/main.tf`  
**Block:** `terraform { backend "gcs" { ... } }`

Replace the placeholder with your **actual GCP project ID**:

| Current value                 | Update to                          |
|------------------------------|-------------------------------------|
| `bucket = "YOUR_PROJECT_ID-terraform-state"` | `bucket = "YOUR_ACTUAL_PROJECT_ID-terraform-state"` |

Example: if `project_id` is `my-project-123`, set:

```hcl
bucket = "my-project-123-terraform-state"
```

Create the bucket in GCP first (see `docs/GKE-DEPLOYMENT.md`).  
If you use **GitHub Actions**, the workflow overrides the bucket via `-backend-config`, so you can leave the bucket name in `main.tf` matching your project or rely on the workflow.

---

## 3. Optional values (main.tf – module arguments)

These have defaults; change only if you need different sizing or networking.

**File:** `Terraform/environments/test/main.tf`

| Module    | Argument          | Default    | When to change                         |
|-----------|-------------------|------------|----------------------------------------|
| **vpc**   | `public_subnet_1_cidr`  | `10.0.1.0/24`  | Custom VPC CIDRs                       |
| **vpc**   | `public_subnet_2_cidr`  | `10.0.2.0/24`  | Same                                   |
| **vpc**   | `private_subnet_1_cidr` | `10.0.11.0/24` | Same                                   |
| **vpc**   | `private_subnet_2_cidr` | `10.0.12.0/24` | Same                                   |
| **gke**   | `node_count`       | `2`        | Initial number of nodes                 |
| **gke**   | `min_node_count`   | `2`        | Min nodes (autoscaling)                 |
| **gke**   | `max_node_count`   | `5`        | Max nodes (autoscaling)                 |
| **gke**   | `machine_type`     | `e2-medium`| Larger/smaller nodes                    |
| **secrets** | `secrets`        | placeholders | Real DB URL and API key (use Secret Manager or env) |

---

## 4. Summary checklist

- [ ] Create `terraform.tfvars` from `terraform.tfvars.example`.
- [ ] Set **project_id** in `terraform.tfvars` to your GCP project ID.
- [ ] Set **region** in `terraform.tfvars` (e.g. `us-central1`).
- [ ] Set **environment** in `terraform.tfvars` if not using `dev`.
- [ ] In `main.tf`, replace `YOUR_PROJECT_ID` in the backend **bucket** with your project ID (or rely on CI `-backend-config`).
- [ ] (Optional) Adjust GKE node count, machine type, or VPC CIDRs in `main.tf`.
- [ ] (Optional) Replace placeholder values in **secrets** with real values (prefer Secret Manager / env in production).

After that, run `terraform init` and `terraform plan -var-file=terraform.tfvars` (or use the GitHub Actions workflow).
