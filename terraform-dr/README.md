# Week 08 – Multi-Region Disaster Recovery (Phase 1 Foundation)

Automated infrastructure provisioning for:

- **Primary (Active)**: Australia East  
- **Secondary (DR)**: Australia Southeast  

This implements **Phase 1** of the DR + Configuration Drift Detection architecture.

## What is provisioned

| Resource                    | Primary (Australia East) | Secondary (Australia Southeast) |
|----------------------------|---------------------------|---------------------------------|
| Resource Group             |                           |                                 |
| AKS Cluster                |  (3 nodes, AZ-aware)      |  (2 nodes)                      |
| Storage Account            |  (GRS)                    |  (LRS)                          |
| Blob containers            |                         mm|                                 |
| Azure Container Registry   |  Premium + geo-replication to secondary|(replicates images) |

Later phases will add:
- Azure Database for PostgreSQL Flexible Server + cross-region read replica + Virtual Endpoints
- Azure Front Door / Traffic Manager
- Azure Automation runbooks for automated failover
- Drift detection pipelines

## Prerequisites

1. Azure CLI logged in (`az login`) with a subscription that can create resources in both Australian regions.
2. Terraform >= 1.7.0.
3. A service principal or user with Contributor rights on the subscription (or the two resource groups once created).

## Quick start (manual)

```bash
cd terraform-dr

# 1. Create your own tfvars (do NOT commit real secrets)
cp terraform.tfvars.example terraform.tfvars
# Edit unique names (acr_name, storage names) and set postgres_admin_password

# 2. Initialise
terraform init

# 3. Plan
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
```

After apply, note the outputs:

```bash
terraform output
# Especially:
#   primary_aks_get_credentials
#   secondary_aks_get_credentials
#   acr_login_server
```

Connect to primary AKS:

```bash
$(terraform output -raw primary_aks_get_credentials)
kubectl get nodes
```

## Automated provisioning via GitHub Actions

A starter workflow is provided in `.github/workflows/terraform-dr-provision.yml`.

Required GitHub secrets / variables:

| Name                  | Type     | Description                                      |
|-----------------------|----------|--------------------------------------------------|
| `AZURE_CREDENTIALS`   | Secret   | Service principal JSON (same as existing week08) |
| `TF_VAR_postgres_admin_password` | Secret | Strong password for PostgreSQL admin             |

The workflow can be triggered manually (`workflow_dispatch`) or on push to `main` when files under `terraform-dr/` change.

## Naming conventions used

- Resource groups: `rg-koalatech-aue-prod` / `rg-koalatech-aus-prod`
- AKS: `aks-koalatech-aue` / `aks-koalatech-aus`
- ACR: single global Premium registry with geo-replication
- Storage: separate accounts per region (primary uses GRS)

## Next steps (Phase 2+)

Once Phase 1 is applied successfully:

1. Add PostgreSQL Flexible Server (primary) + cross-region read replica (secondary).
2. Configure Virtual Endpoints.
3. Deploy Azure Front Door with priority routing to both AKS ingresses.
4. Create Azure Automation runbooks for automated promote + traffic switch.
5. Wire Azure Monitor / Service Health alerts to the runbooks.
6. Add scheduled Terraform plan + GitOps drift detection.

See the main project documentation for the full phased plan.