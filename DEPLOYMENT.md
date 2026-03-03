# FinOps AI Assistant – Deployment Guide

This guide walks you through installing the FinOps AI Assistant, including **challenges we encountered with Quick Suite permissions** and how to resolve them. Following these steps should get you from zero to working CUDOS dashboards with Quick Suite.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Suite Setup (Critical)](#quick-suite-setup-critical)
3. [Deployment Steps](#deployment-steps)
4. [Backfilling Historical Data (Optional)](#backfilling-historical-data-optional)
5. [Troubleshooting: Quick Suite Permissions](#troubleshooting-quick-suite-permissions)
6. [Quick Suite Chat Agent Setup](#quick-suite-chat-agent-setup)
7. [GitHub Installation Summary](#github-installation-summary)

---

## Prerequisites

- **Two AWS accounts:** Management (Payer) and Data Collection
- **AWS CLI** configured with profiles for both accounts
- **Quick Suite Enterprise** with **Author Pro** (required for Chat Agents)
- **~40GB SPICE** capacity recommended

```bash
aws configure --profile management-account
aws configure --profile data-collection-access-profile
```

---

## Quick Suite Setup (Critical)

Before deploying CID dashboards, you **must** complete Quick Suite setup. We encountered several failures that were resolved only after these steps.

### 1. Enterprise Edition + Author Pro

- **Standard Edition does not support** Chat Agents or generative AI.
- You need [Quick Suite Enterprise](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html) with at least one **Author Pro** user (~$40/user/month).

### 2. QuickSight Service Role (Required for Step 3)

The CID CloudFormation creates an Athena data source. QuickSight needs a **service role** to access S3 and Athena.

**If you skip this:** Step 3 fails with:
> "The QuickSight service role required to access your AWS resources has not been created yet."

**How to fix:**
1. Open [Quick Suite console](https://us-east-1.quicksight.aws.amazon.com/) in your **Data Collection account**.
2. Go to **Manage Quick Suite** (or your user menu → Manage Quick Suite).
3. Navigate to **Security & permissions** (or **QuickSight access to AWS services**).
4. Configure or create the QuickSight service role for access to S3 and Athena.
5. Apply the required IAM permissions (or use the guided setup).

### 3. QuickSight User Format for CID Template

The CID CloudFormation template expects the **username only**, not the full `default/username` format.

**Wrong (causes failure):**
```bash
QUICKSIGHT_USER="default/v_2udan@hotmail.com"
```

**Correct:**
```bash
QUICKSIGHT_USER="v_2udan@hotmail.com"
```

**If you use the wrong format:** Step 3 fails with:
> "One or more principals in resource permissions list are not valid QuickSight users" (CidAthenaDataSource)

**Why:** The CID template constructs the user ARN as `arn:aws:quicksight:...:user/default/${QuickSightUser}`. If you pass `default/username`, it becomes `user/default/default/username` — invalid.

**How to get your username:** QuickSight admin panel → Users → your user. Use only the part after `default/` (e.g., `v_2udan@hotmail.com` or `FinOps-Admin`).

---

## Deployment Steps

### Step 0: Enable Cost Optimization Hub (Management Account)

```bash
aws cost-optimization-hub update-enrollment-status \
  --status Active \
  --profile management-account \
  --region us-east-1
```

Or use the deploy script: `./deploy-cid.sh step0`

### Step 1: Deploy Destination (Data Collection Account)

Creates S3 bucket, Athena tables, Glue crawlers.

```bash
cd deploy
cp config.sh.example config.sh
# Edit config.sh with MANAGEMENT_ACCOUNT_ID and DATA_COLLECTION_ACCOUNT_ID

./deploy-cid.sh step1
```

### Step 2: Deploy Source (Management Account)

Creates CUR 2.0 export, COH, FOCUS, S3 replication to Data Collection.

```bash
./deploy-cid.sh step2
```

> **Note:** Data delivery takes 24–48 hours. You can proceed to Step 3 before data arrives.

### Step 3: Deploy Dashboards (Data Collection Account)

**Before running Step 3, ensure:**
- [ ] QuickSight service role is configured (see above)
- [ ] `QUICKSIGHT_USER` in config.sh uses **username only** (e.g., `v_2udan@hotmail.com`)

```bash
# Edit config.sh:
export QUICKSIGHT_USER="v_2udan@hotmail.com"   # NOT "default/v_2udan@hotmail.com"

./deploy-cid.sh step3
```

Step 3 takes ~5–15 minutes. On success, you'll get dashboard URLs:
- CUDOS v5
- Cost Intelligence Dashboard
- KPI Dashboard

---

## Backfilling Historical Data (Optional)

If you have **existing CUR 2.0 data** in an S3 bucket and want to backfill without waiting for replication:

```bash
# Prerequisites: Step 1 completed. Edit config.sh if your bucket/prefix differ.
./copy-cur-to-cid.sh
```

See [deploy/README.md](deploy/README.md#copy-existing-cur-20-data-backfill-option) for configuration options.

---

## Troubleshooting: Quick Suite Permissions

### Error: "One or more principals in resource permissions list are not valid QuickSight users"

**Cause:** `QUICKSIGHT_USER` includes `default/` prefix.

**Fix:** Use only the username:
```bash
# Wrong
export QUICKSIGHT_USER="default/FinOps-Admin"

# Correct
export QUICKSIGHT_USER="FinOps-Admin"
```

Then delete the failed stack and retry:
```bash
aws cloudformation delete-stack --stack-name Cloud-Intelligence-Dashboards --profile data-collection-access-profile --region us-east-1
# Wait ~2 mins
./deploy-cid.sh step3
```

---

### Error: "The QuickSight service role required to access your AWS resources has not been created yet"

**Cause:** QuickSight service role not configured for S3/Athena access.

**Fix:** 
1. Manage Quick Suite → Security & permissions
2. Configure the QuickSight service role
3. Ensure it has access to S3 (CUR bucket, Athena results) and Athena
4. Delete failed stack and retry Step 3

---

### Error: "No export named cid-DataExports-ReadAccessPolicyARN found"

**Cause:** Step 1 not complete or ManageCUR2 was not set to `yes`.

**Fix:** Re-run Step 1 and ensure CUR 2.0 is enabled.

---

## Quick Suite Chat Agent Setup

After dashboards are deployed:

1. Create a **Space** in Quick Suite.
2. Add your CID dashboards to the space.
3. Create a **Chat Agent** (e.g., "CID Operations Advisor") connected to that space.
4. Configure flows and test prompts.

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed steps.

---

## GitHub Installation Summary

```bash
# 1. Clone the repository
git clone https://github.com/udaykirannag2/FinOps-AI-Assistant.git
cd finops-ai-assistant/deploy

# 2. Configure
cp config.sh.example config.sh
# Edit config.sh: account IDs, QUICKSIGHT_USER (username only!)

# 3. Deploy (ensure QuickSight service role is configured first)
chmod +x deploy-cid.sh copy-cur-to-cid.sh
./deploy-cid.sh step0
./deploy-cid.sh step1
./deploy-cid.sh step2
./deploy-cid.sh step3

# 4. (Optional) Backfill existing CUR data
./copy-cur-to-cid.sh

# 5. Set up Chat Agent
# Follow SETUP_GUIDE.md
```

**Quick checklist before Step 3:**
- [ ] Quick Suite Enterprise + Author Pro
- [ ] QuickSight service role configured (Manage Quick Suite → Security & permissions)
- [ ] QUICKSIGHT_USER = username only (no `default/` prefix)

---

## For Repository Maintainers

Clone URLs use `udaykirannag2/FinOps-AI-Assistant`. Fork the repo and update URLs if you publish your own copy.

---

## References

- [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)
- [Cloud Intelligence Dashboards Deployment](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)
- [Generative AI with CID and Quick Suite](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html)
