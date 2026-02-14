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
- [ ] **QuickSight** – Sign up in Data Collection account (~40GB SPICE recommended)
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

| # | Action | Status |
|---|--------|--------|
| 1 | Sign up for QuickSight in Data Collection account if not already | ☐ |
| 2 | Choose region matching Step 1 | ☐ |
| 3 | Select authentication (IAM Identity Center recommended for production) | ☐ |
| 4 | Purchase ~40GB SPICE capacity (auto-purchase or manual) | ☐ |
| 5 | Get your **QuickSight username** (person icon → top right) | ☐ |

### 3.2 – Deploy Dashboards via CloudFormation

| # | Action | Status |
|---|--------|--------|
| 1 | Sign in to **Data Collection Account** | ☐ |
| 2 | Open [Launch Stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?templateURL=https://aws-managed-cost-intelligence-dashboards.s3.amazonaws.com/cfn/cid-cfn.yml&stackName=Cloud-Intelligence-Dashboards&param_DeployCUDOSv5=yes&param_DeployKPIDashboard=yes&param_DeployCostIntelligenceDashboard=yes) | ☐ |
| 3 | Stack name: `Cloud-Intelligence-Dashboards` | ☐ |
| 4 | Answer both prerequisites = `yes` | ☐ |
| 5 | Enter **QuickSightUserName** | ☐ |
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
| `No export named cid-CidExecArn found` | Deploy foundational dashboards (Step 3) before CORA/FOCUS |
| No data after 24–48 hours | Check QuickSight Datasets for refresh errors; manually refresh |
| TAO no data | Deploy Data Collection with Trusted Advisor module; verify Support Plan |

---

## Documentation Links

- [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)
- [All CID Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/dashboards.html)
- [CORA Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/cora-dashboard.html)
- [FOCUS Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/focus-dashboard.html)
- [Trusted Advisor (TAO) Dashboard](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/trusted-advisor-dashboard.html)
- [CID Framework GitHub](https://github.com/aws-solutions-library-samples/cloud-intelligence-dashboards-framework)
