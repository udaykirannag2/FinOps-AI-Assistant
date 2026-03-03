# FinOps AI Assistant – Official CID Deployment Guide

This guide follows the **[official AWS Cloud Intelligence Dashboards deployment](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)** using AWS CloudFormation templates. The official deployment provides built-in dashboards (CUDOS, Cost Intelligence, KPI, CORA, TAO, FOCUS, and more) with minimal configuration.

---

## Official Deployment Overview

| Step | Account | Action |
|------|---------|--------|
| **Step 1** | Data Collection | Create destination bucket + Athena tables for CUR aggregation |
| **Step 2** | Management (Payer) | Create CUR 2.0 + Data Exports + replication to Data Collection |
| **Step 3** | Data Collection | Deploy dashboards (CloudFormation or cid-cmd) |

**Reference:** [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)

---

## Note: Previous Custom Setup

If you previously created a custom bucket (`cur-finops-data`) and replication from `curbucketforroot`, that setup is **not** used by the official CID deployment. You can:

- **Leave it as-is** – It won't conflict; the official stack creates its own bucket.
- **Decommission it** – Delete the replication rule, `cur-finops-data` bucket, and related IAM roles if no longer needed.

The official deployment uses templates that create properly structured buckets and Athena tables for all built-in dashboards.

---

## Before You Start

- [ ] **Region** – Choose one region for all stacks (e.g., `us-east-1`)
- [ ] **Data Collection Account** – Dedicated account (not Management)
- [ ] **Management (Payer) Account** – Source of CUR data
- [ ] **Quick Suite Enterprise** – Sign up in Data Collection account with at least one **Author Pro** user (~40GB SPICE recommended)
  - Chat Agents and generative AI features require **Enterprise** edition; Standard does not support them
  - See [Costs](#costs) below and [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)
- [ ] **Permissions** – CloudFormation, CUR/Data Exports, S3, Glue, Athena, QuickSight, Lambda

---

## Step 0: Enable Cost Optimization Hub (Management Account)

Required for the **CORA dashboard**. Run in your Management (Payer) account before Step 2.

**CLI (recommended):**
```bash
aws cost-optimization-hub update-enrollment-status \
  --status Active \
  --profile management-account \
  --region us-east-1
```

**Optional – enroll all member accounts** (if using AWS Organizations):
```bash
aws cost-optimization-hub update-enrollment-status \
  --status Active \
  --include-member-accounts \
  --profile management-account \
  --region us-east-1
```

**Console alternative:** [Cost Optimization Hub](https://console.aws.amazon.com/costmanagement/home#/cost-optimization-hub) → Activate the service.

---

## Step 1: [Data Collection Account] Create Destination For CUR Aggregation

| # | Action | Status |
|---|--------|--------|
| 1 | Sign in to your **Data Collection Account** | ☐ |
| 2 | Open [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html) | ☐ |
| 3 | Scroll to **Step 1** and click **Launch Stack** | ☐ |
| 4 | Set **DestinationAccountId** = Data Collection Account ID | ☐ |
| 5 | Set **Manage CUR 2.0** = `yes` | ☐ |
| 6 | Set **Cost Optimization Hub** = `yes` (for CORA) | ☐ |
| 7 | Set **FOCUS** = `yes` (for FOCUS dashboard) | ☐ |
| 8 | Set **SourceAccountIds** = comma-separated Management Account ID(s) | ☐ |
| 9 | Acknowledge IAM resources → **Create stack** | ☐ |
| 10 | Wait for **CREATE_COMPLETE** (~5–15 mins) | ☐ |

---

## Step 2: [Management/Payer Account] Create CUR 2.0 and Replication

| # | Action | Status |
|---|--------|--------|
| 1 | Sign in to your **Management (Payer) Account** | ☐ |
| 2 | Open [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html) | ☐ |
| 3 | Scroll to **Step 2** and click **Launch Stack** | ☐ |
| 4 | Stack name: `CID-DataExports-Source` | ☐ |
| 5 | **DestinationAccountId** = Data Collection Account ID | ☐ |
| 6 | Exports = same as Step 1 (CUR 2.0, COH, FOCUS) | ☐ |
| 7 | Acknowledge IAM resources → **Create stack** | ☐ |
| 8 | Wait for **CREATE_COMPLETE** (~5 mins) | ☐ |
| 9 | Repeat for other Source accounts if needed | ☐ |

> **Data delivery:** First data arrives in **24–48 hours** (up to 72 hours). You can deploy Step 3 before data arrives.

---

## Step 3: [Data Collection Account] Deploy Dashboards

### 3.1 – Prepare QuickSight (Quick Suite)

**Requirements:** Use **Quick Suite Enterprise** with at least one **Author Pro** user. Chat Agents and generative AI features are not available in Standard edition. See [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html).

| # | Action | Status |
|---|--------|--------|
| 1 | Sign up for Quick Suite in Data Collection account (Enterprise edition) | ☐ |
| 2 | Configure at least one **Author Pro** subscription | ☐ |
| 3 | Choose region matching Step 1 | ☐ |
| 4 | Select authentication (IAM Identity Center recommended for production) | ☐ |
| 5 | Purchase ~40GB SPICE capacity (auto-purchase or manual) | ☐ |
| 6 | **Configure QuickSight service role** (Manage Quick Suite → Security & permissions) for S3/Athena access | ☐ |
| 7 | Get your **QuickSight username** – use only the username (e.g., `v_2udan@hotmail.com`), **not** `default/username` | ☐ |

### 3.2 – Deploy Dashboards via CloudFormation

| # | Action | Status |
|---|--------|--------|
| 1 | Sign in to **Data Collection Account** | ☐ |
| 2 | Open [Launch Stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/cid-cfn.yml&stackName=Cloud-Intelligence-Dashboards&param_DeployCUDOSv5=yes&param_DeployKPIDashboard=yes&param_DeployCostIntelligenceDashboard=yes) | ☐ |
| 3 | Stack name: `Cloud-Intelligence-Dashboards` | ☐ |
| 4 | Answer both prerequisites = `yes` | ☐ |
| 5 | Enter **QuickSightUser** – username only (e.g., `v_2udan@hotmail.com`), not `default/username` | ☐ |
| 6 | Select dashboards to install (recommended: all three) | ☐ |
|    | ☐ **Cost Intelligence Dashboard** | |
|    | ☐ **CUDOS v5** | |
|    | ☐ **KPI Dashboard** | |
| 7 | Acknowledge IAM resources → **Create stack** | ☐ |
| 8 | Wait for **CREATE_COMPLETE** (~15 mins) | ☐ |

### 3.3 – Deploy Additional Dashboards (CORA, FOCUS, TAO)

After foundational dashboards are deployed:

| Dashboard | Requirement | Launch Stack / CLI |
|-----------|-------------|--------------------|
| **CORA** | COH enabled in Step 1 & 2 | [CORA Stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/cid-plugin.yml&stackName=CORA-Dashboard&param_DashboardId=cora&param_RequiresDataExports=yes) or `cid-cmd deploy --dashboard-id cora` |
| **FOCUS** | FOCUS enabled in Step 1 & 2 | [FOCUS Stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/cid-plugin.yml&stackName=FOCUS-Dashboard&param_DashboardId=focus-dashboard&param_RequiresDataExports=yes) or `cid-cmd deploy --dashboard-id focus-dashboard` |
| **TAO** | Data Collection + Trusted Advisor module | Update stack with `DeployTaoDashboard=yes` or `cid-cmd deploy --dashboard-id ta-organizational-view` |

---

## Built-in Dashboards (Official Deployment)

| Category | Dashboard | Description |
|----------|-----------|-------------|
| **Foundational** | CUDOS v5 | Cost & usage with resource-level drill-down |
| **Foundational** | Cost Intelligence | Executive-friendly cost management |
| **Foundational** | KPI Dashboard | Modernization goals (Spot, Graviton, etc.) |
| **Additional** | CORA | Cost Optimization Recommended Actions |
| **Additional** | FOCUS | FinOps Cost and Usage Specification |
| **Advanced** | TAO | Trusted Advisor Organizational View |
| **Advanced** | Compute Optimizer | Rightsizing recommendations |
| **Advanced** | Cost Anomaly | Cost anomaly detection |
| **Advanced** | Graviton Savings | Graviton migration opportunities |
| **Advanced** | Health Events | AWS Health Dashboard events |
| **Advanced** | Support Cases Radar | Support case consolidation |
| **Advanced** | ResilienceVue | Resilience posture (Resilience Hub) |
| **Additional** | Extended Support | RDS/EKS Extended Support costs |
| **Additional** | Budgets | AWS Budgets visualization |

See [Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/dashboards.html) for the full list.

---

## Optional: Backfill Historical Data

You have two options to get historical CUR 2.0 data into CID:

### Option A: Copy existing CUR 2.0 from your bucket

If you already have CUR 2.0 data in an S3 bucket (e.g., `curbucketforroot` with `costreports/CUR/data/`), use the copy script:

```bash
cd deploy
./copy-cur-to-cid.sh
```

See [deploy/README.md – Copy Existing CUR 2.0 Data](./deploy/README.md#copy-existing-cur-20-data-backfill-option) for configuration (bucket names, prefixes).

### Option B: AWS Support backfill

Request up to 36 months of historical data via AWS Support (from Management account):

```
Service: Billing
Category: Other Billing Questions
Subject: Backfill Data

Hello Dear Billing Team,
Please can you backfill the data in DataExport named `cid-cur2` for last 12 months.
Thanks in advance,
```

---

## Automated Deployment (deploy-cid.sh)

A deployment script is available in `deploy/`:

```bash
cd deploy
cp config.sh.example config.sh
# Edit config.sh with your account IDs and QUICKSIGHT_USER

./deploy-cid.sh step0   # Enable Cost Optimization Hub (optional if done manually)
./deploy-cid.sh step1   # Then step2, then step3
# Or: ./deploy-cid.sh all
```

See [deploy/README.md](./deploy/README.md) for details.

---

## CLI Alternative (cid-cmd)

```bash
pip3 install --upgrade cid-cmd
cid-cmd deploy --dashboard-id cudos-v5
cid-cmd deploy  # for Cost Intelligence and KPI
cid-cmd deploy --dashboard-id cora
cid-cmd deploy --dashboard-id focus-dashboard
cid-cmd deploy --dashboard-id ta-organizational-view
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `No export named cid-DataExports-ReadAccessPolicyARN found` | Step 1 not complete or ManageCUR2 not `yes` |
| `One or more principals... are not valid QuickSight users` (CidAthenaDataSource) | Use **username only** for QuickSightUser (e.g., `v_2udan@hotmail.com`), not `default/username` |
| `QuickSight service role required... has not been created yet` | Configure QuickSight role: Manage Quick Suite → Security & permissions |
| `No export named cid-CidExecArn found` | Deploy foundational dashboards (Step 3) before CORA/FOCUS |
| No data after 24–48 hours | Check QuickSight Datasets for refresh errors; manually refresh |
| TAO no data | Deploy Data Collection with Trusted Advisor module; verify Support Plan |

---

## Costs

For the FinOps AI Assistant (with CID + Chat Agent):

| Component | Est. Monthly Cost |
|-----------|--------------------|
| **Quick Suite Author Pro** (1 user) | $40 |
| **SPICE** (~40GB) | ~$15 or included |
| **CID infrastructure** (S3, Athena, Glue, Lambda) | ~$5–15 |
| **Total** | **~$50–70/month** |

Configure your subscription: [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html). You must use **Enterprise edition** and provision at least one **Author Pro** user for Chat Agents and generative AI. Standard edition does not support these capabilities.

---

## Documentation Links

- [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)
- [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)
- [All CID Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/dashboards.html)
- [CORA Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/cora-dashboard.html)
- [FOCUS Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/focus-dashboard.html)
- [Trusted Advisor (TAO) Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/trusted-advisor-dashboard.html)
- [CID Framework GitHub](https://github.com/aws-solutions-library-samples/cloud-intelligence-dashboards-framework)
