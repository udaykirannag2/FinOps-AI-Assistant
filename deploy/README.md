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

3. **QuickSight** signed up in Data Collection account (~40GB SPICE recommended)

## Configuration

```bash
cp config.sh.example config.sh
```

Edit `config.sh` with your values:

```bash
# Account IDs (get with: aws sts get-caller-identity --profile <profile> --query Account --output text)
MANAGEMENT_ACCOUNT_ID="123456789012"
DATA_COLLECTION_ACCOUNT_ID="098765432109"

# For Step 3 only - get from QuickSight console (person icon → top right)
QUICKSIGHT_USER="default/your-username"
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

## Notes

- **Data delivery:** First CUR data arrives in 24–48 hours (up to 72h)
- **Same region:** Use the same region for all stacks to avoid data transfer charges
- **Stack exists:** If a stack already exists, delete it first or use the AWS Console to update
