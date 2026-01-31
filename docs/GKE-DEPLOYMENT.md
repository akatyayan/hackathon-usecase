# GKE Deployment Guide – Terraform, Helm, GitHub Actions

This guide walks through deploying all applications (application-service, patient-service, order-service) to **Google Kubernetes Engine (GKE)** using **Terraform**, **Helm**, and **GitHub Actions**, and how to make them accessible.

---

## Architecture Overview

1. **Terraform** – Provisions VPC, GKE cluster, Artifact Registry, IAM, and secrets.
2. **GitHub Actions** – Runs Terraform, builds/pushes Docker images, and deploys with Helm.
3. **Helm** – Deploys the three microservices and an Ingress so they are reachable.

---

## Prerequisites

- **GCP project** with billing enabled.
- **GitHub repo** with this codebase.
- **gcloud CLI** (optional, for local steps): `gcloud auth application-default login`.

---

## Step 1: GCP Setup

### 1.1 Enable APIs

```bash
export PROJECT_ID=your-gcp-project-id
gcloud services enable container.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  --project=$PROJECT_ID
```

### 1.2 Create Terraform state bucket (required for CI)

```bash
gsutil mb -p $PROJECT_ID -l us-central1 gs://${PROJECT_ID}-terraform-state/
gsutil versioning set on gs://${PROJECT_ID}-terraform-state/
```

### 1.3 Service account for GitHub Actions

Create a key for Terraform and CI/CD:

```bash
# Create SA
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions" \
  --project=$PROJECT_ID

# Grant roles (Terraform + GKE + Artifact Registry + Storage)
for role in roles/container.admin roles/artifactregistry.admin roles/compute.networkAdmin roles/iam.serviceAccountUser roles/secretmanager.admin roles/storage.admin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role=$role
done

# Create key (save the JSON securely)
gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com
```

---

## Step 2: GitHub Secrets and Variables

In your repo: **Settings → Secrets and variables → Actions**.

### Required (Workload Identity – no key)

| Type     | Name                 | Description |
|----------|----------------------|-------------|
| **Secret**   | `GCP_PROJECT_ID` | Your GCP project ID |
| **Secret**   | `GCP_PROJECT_NUMBER` | Your GCP project **number** (numeric). Get it: `gcloud projects describe PROJECT_ID --format='value(projectNumber)'` |

The workflows use **Workload Identity Federation** (no `GCP_SA_KEY`). Set up the pool and provider in GCP first (see “Workload Identity” section in this doc or in `docs/EXECUTION-STEPS.md`).

### Optional variable

| Variable     | Description        | Example      |
|-------------|--------------------|-------------|
| `GCP_REGION`| GKE/Artifact region| `us-central1`|

---

## Step 3: Terraform (Infrastructure)

### Option A: Run via GitHub Actions

1. Push to `main` with changes under `Terraform/`, or run the **Terraform** workflow manually (**Actions → Terraform → Run workflow**).
2. On **push to main**, the workflow runs **plan** then **apply** (apply only on the `plan` job success).
3. Ensure `GCP_PROJECT_ID` and `GCP_PROJECT_NUMBER` (both secrets) are set; the workflow uses Workload Identity and backend config:  
   `bucket=${{ secrets.GCP_PROJECT_ID }}-terraform-state`, `prefix=dev/state`.

### Option B: Run locally

```bash
cd Terraform/environments/test
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set project_id, region, environment

# Backend: edit main.tf and set bucket = "YOUR_PROJECT_ID-terraform-state"
# or init with:
terraform init \
  -backend-config="bucket=YOUR_PROJECT_ID-terraform-state" \
  -backend-config="prefix=dev/state"

terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

After apply, you should have:

- VPC and subnets  
- GKE cluster: **dev-gke-cluster** (name from `modules/gke`)  
- Artifact Registry repo: **hackathon-apps**  
- IAM and Secret Manager secrets  

---

## Step 4: Build and Push Images (GitHub Actions)

1. Push to `main` with changes under `application-service/`, `patient-service/`, or `order-service/`, or run **Build and Push Images** manually.
2. The workflow builds all three Docker images and pushes them to:
   - `{REGION}-docker.pkg.dev/{PROJECT_ID}/hackathon-apps/application-service:latest` (and short SHA tag)
   - Same for `patient-service` and `order-service`.

No extra configuration needed if `GCP_SA_KEY` and `GCP_PROJECT_ID` are set.

---

## Step 5: Deploy to GKE with Helm (GitHub Actions)

1. **Automatic**: After **Build and Push Images** completes successfully on `main`, the **Deploy to GKE** workflow runs and deploys with Helm using `latest`.
2. **Manual**: **Actions → Deploy to GKE → Run workflow**. Optionally set **Image tag** (e.g. `latest` or a git SHA tag from build-push).

The deploy job:

- Authenticates to GCP  
- Gets GKE credentials for **dev-gke-cluster** in **us-central1** (overridable via `GKE_CLUSTER_NAME` / `GKE_REGION` in the workflow)  
- Runs:  
  `helm upgrade --install hackathon-apps ./helm/hackathon-apps --set global.imageRegistry=... --set global.imageTag=...`

---

## Step 6: Make Applications Accessible

### Ingress and external IP

The Helm chart creates an Ingress (GCE class). After deploy:

1. Get the Ingress (external IP can take 5–10 minutes on GKE):

   ```bash
   kubectl get ingress -A
   # Or: kubectl get ingress hackathon-apps-ingress
   ```

2. Once `ADDRESS` is set, use:

   - **Application service**: `http://<EXTERNAL_IP>/application`  
   - **Patient service**: `http://<EXTERNAL_IP>/patient`  
   - **Order service**: `http://<EXTERNAL_IP>/order`  

Path routing is defined in `helm/hackathon-apps/values.yaml` under `ingress.hosts[0].paths`.

### Optional: use a domain

- In GCP **Network services → Load balancing**, find the HTTP(S) load balancer created by the Ingress.
- Add a static IP and point your DNS A record to it, then (if needed) add a host in `ingress.hosts[].host` and re-deploy.

### Access without Ingress (for testing)

```bash
kubectl port-forward svc/application-service 3001:3001
kubectl port-forward svc/patient-service 3000:3000
kubectl port-forward svc/order-service 8080:8080
# Then: http://localhost:3001, http://localhost:3000, http://localhost:8080
```

---

## Summary: End-to-End Flow

| Order | Step              | How                               |
|-------|-------------------|------------------------------------|
| 1     | Enable APIs       | gcloud (one-time)                  |
| 2     | Create state bucket | gcloud (one-time)                |
| 3     | Create SA + key   | gcloud (one-time)                  |
| 4     | Set GitHub secrets| `GCP_SA_KEY`, `GCP_PROJECT_ID`     |
| 5     | Apply Terraform   | Push to main or run Terraform workflow |
| 6     | Build images      | Push to main or run Build and Push workflow |
| 7     | Deploy Helm       | Auto after build or run Deploy workflow |
| 8     | Get Ingress IP    | `kubectl get ingress`              |
| 9     | Access apps       | `http://<EXTERNAL_IP>/application`, `/patient`, `/order` |

---

## Troubleshooting

- **Terraform apply fails in CI**  
  - Ensure the state bucket exists and the SA has `roles/storage.admin` (or equivalent) on it.  
  - Ensure backend config in the workflow matches your bucket name.

- **Build-push fails**  
  - Ensure Artifact Registry API is enabled and SA has `roles/artifactregistry.admin` (or equivalent).  
  - Ensure Dockerfiles and context paths in the workflow match your repo layout.

- **Deploy fails: “cluster not found”**  
  - Confirm cluster name and region in the deploy workflow (`GKE_CLUSTER_NAME`, `GKE_REGION`) match Terraform (e.g. **dev-gke-cluster**, **us-central1**).

- **No external IP on Ingress**  
  - Wait 5–10 minutes.  
  - Check `kubectl describe ingress hackathon-apps-ingress` and backend health in the GCP load balancer.

- **502 / connection errors**  
  - Check app logs: `kubectl logs -l app=application-service` (and same for patient/order).  
  - Ensure services listen on the port specified in the Helm values (3001, 3000, 8080) and that Ingress paths match how your apps expect to be called (e.g. `/application` vs `/`).

---

## Files Reference

- **Terraform**: `Terraform/environments/test/` (main.tf, variables, outputs), `Terraform/modules/*`
- **Helm**: `helm/hackathon-apps/` (Chart.yaml, values.yaml, templates/)
- **GitHub Actions**: `.github/workflows/terraform.yml`, `build-push.yml`, `deploy.yml`
