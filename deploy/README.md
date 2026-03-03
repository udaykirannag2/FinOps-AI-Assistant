# CID Deployment Automation

Automated deployment of [Cloud Intelligence Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html) using AWS CLI.

## Prerequisites

1. **AWS CLI profiles** configured:
   ```bash
   aws configure --profile management-account
   aws configure --profile data-collection-access-profile
   ```

2. **Cost Optimization Hub** enabled (required for CORA dashboard):
   ```bash
   aws cost-optimization-hub update-enrollment-status \
     --status Active \
     --profile management-account \
     --region us-east-1
   ```
   Or via console: [Cost Optimization Hub](https://console.aws.amazon.com/costmanagement/home#/cost-optimization-hub)

3. **Quick Suite Enterprise** with at least one **Author Pro** user in Data Collection account (~40GB SPICE recommended)
   - Chat Agents require Enterprise; Standard edition does not support them  
   - [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)
4. **QuickSight service role** configured (Manage Quick Suite → Security & permissions) – required for Athena/S3 data source access

## Configuration

```bash
cp config.sh.example config.sh
```

Edit `config.sh` with your values:

```bash
# Account IDs (get with: aws sts get-caller-identity --profile <profile> --query Account --output text)
MANAGEMENT_ACCOUNT_ID="123456789012"
DATA_COLLECTION_ACCOUNT_ID="098765432109"

# For Step 3 only - use ONLY the username, NOT "default/username"
# Example: "v_2udan@hotmail.com" or "FinOps-Admin" (get from QuickSight admin panel)
QUICKSIGHT_USER="your-username"
```

## Usage

```bash
chmod +x deploy-cid.sh

# Deploy step by step
./deploy-cid.sh step0   # Enable Cost Optimization Hub (Management account) - required for CORA
./deploy-cid.sh step1   # Data Collection account - destination
./deploy-cid.sh step2   # Management account - source + CUR
./deploy-cid.sh step3   # Data Collection account - dashboards (requires QUICKSIGHT_USER)

# Or deploy all steps (Step 3 requires QUICKSIGHT_USER in config.sh)
./deploy-cid.sh all
```

## Deployment Order

| Step | Account | What it deploys |
|------|---------|-----------------|
| step0 | Management | Enable Cost Optimization Hub (required for CORA) |
| step1 | Data Collection | Destination S3 bucket, Athena tables, Glue crawlers |
| step2 | Management | CUR 2.0 export, COH export, FOCUS export, S3 replication |
| step3 | Data Collection | CUDOS v5, Cost Intelligence, KPI dashboards |

## Copy Existing CUR 2.0 Data (Backfill Option)

If you already have **CUR 2.0 data** in an S3 bucket (e.g., from a previous setup) and want to backfill CID without waiting for new Data Exports or an AWS Support backfill, use `copy-cur-to-cid.sh`:

```bash
# Prerequisites: Step 1 completed. Your CUR 2.0 in Management account bucket.
./copy-cur-to-cid.sh
```

**What it does:**
- Copies CUR 2.0 parquet files from your source bucket to the CID Data Collection bucket
- Uses local staging (download with Management profile → upload with Data Collection profile) for cross-account copy
- Starts the Glue crawler to register new partitions

**Configuration:** Edit `config.sh` or set env vars:
- `CUR_SOURCE_BUCKET` – Source bucket (default: `curbucketforroot`)
- `CUR_SOURCE_PREFIX` – Prefix under bucket (default: `costreports/CUR/data`)
- `CID_DATA_EXPORTS_BUCKET` – Data Collection bucket (default: `cid-<account-id>-data-exports`)
- `MANAGEMENT_ACCOUNT_ID` – Used in destination path

**Expected source structure:** `s3://<bucket>/<prefix>/BILLING_PERIOD=YYYY-MM/*.parquet`

See [PREREQUISITES_DEPLOYMENT_GUIDE.md](../PREREQUISITES_DEPLOYMENT_GUIDE.md#optional-backfill-historical-data) for the AWS Support backfill alternative.

---

## Step 3: QuickSight Setup Requirements

Before running Step 3, ensure:

| Requirement | Details |
|-------------|---------|
| **QUICKSIGHT_USER format** | Use only the username (e.g., `v_2udan@hotmail.com`), **not** `default/username`. The CID template adds `default/` automatically. Using `default/username` causes *"One or more principals in resource permissions list are not valid QuickSight users"* on CidAthenaDataSource. |
| **QuickSight service role** | Go to **Manage Quick Suite** → **Security & permissions** and configure the QuickSight service role for access to S3 and Athena. Without it, Step 3 fails with *"The QuickSight service role required to access your AWS resources has not been created yet."* |

---

## Notes

- **Data delivery:** First CUR data arrives in 24–48 hours (up to 72h)
- **Same region:** Use the same region for all stacks to avoid data transfer charges
- **Stack exists:** If a stack already exists, delete it first or use the AWS Console to update
