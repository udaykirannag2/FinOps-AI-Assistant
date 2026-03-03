# FinOps AI Assistant

Deploy a **Generative AI FinOps Assistant** using [AWS Cloud Intelligence Dashboards (CID)](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/) and [Amazon Quick Suite](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html). Ask natural language questions about your AWS costs, optimization opportunities, security, and operations.

## Install from GitHub

```bash
git clone https://github.com/udaykirannag2/FinOps-AI-Assistant.git
cd finops-ai-assistant
```

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** for the full installation guide, including **Quick Suite permission challenges** and how to resolve them.

## What You Get

- **CUDOS v5** – Cost & usage insights with resource-level drill-down
- **Cost Intelligence Dashboard** – Executive-friendly cost management
- **KPI Dashboard** – Modernization goals (Spot, Graviton, etc.)
- **CORA** – Cost Optimization Recommended Actions
- **FOCUS Dashboard** – FinOps Cost and Usage Specification
- **Quick Suite Chat Agent** – AI-powered FinOps advisor across all dashboards

## Quick Suite Requirements

**Enterprise Edition with Author Pro is required** for the FinOps AI Assistant. Chat Agents, Flows, and other generative AI features are only available in [Quick Suite Enterprise](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html). Standard Edition does not support these capabilities.

| Requirement | Reason |
|-------------|--------|
| **Enterprise Edition** | New Quick Suite features (Chat Agents, Flows, Research) are Enterprise-only |
| **Author Pro** ($40/user/month) | Includes generative AI tools, Chat Agents, Amazon Q Topics, natural language dashboard building |

See [Costs](#costs) below for estimated monthly costs.

---

## Quick Start

### 1. Prerequisites

- Two AWS accounts: **Management (Payer)** and **Data Collection**
- [AWS CLI](https://aws.amazon.com/cli/) configured with profiles for both accounts
- **Quick Suite Enterprise** with at least one **Author Pro** user in Data Collection account
- ~40GB SPICE capacity recommended

### 2. Enable Cost Optimization Hub (Management Account)

Required for the CORA dashboard:

```bash
aws cost-optimization-hub update-enrollment-status \
  --status Active \
  --profile management-account \
  --region us-east-1
```

### 3. Deploy CID Dashboards

```bash
cd deploy
cp config.sh.example config.sh
# Edit config.sh with your account IDs and QuickSight user (username only – see DEPLOYMENT.md)

./deploy-cid.sh step0   # Enable Cost Optimization Hub (if not done above)
./deploy-cid.sh step1   # Data Collection account – destination
./deploy-cid.sh step2   # Management account – source + CUR
./deploy-cid.sh step3   # Data Collection account – dashboards

# Or run all: ./deploy-cid.sh all
```

> **Important:** Before Step 3, configure the QuickSight service role and use **username only** for `QUICKSIGHT_USER`. See [DEPLOYMENT.md – Quick Suite Setup](./DEPLOYMENT.md#quick-suite-setup-critical).

### 4. Configure Quick Suite Chat Agent

Follow [SETUP_GUIDE.md](./SETUP_GUIDE.md) to create the CID Operations Advisor chat agent in Quick Suite.

## Project Structure

```
├── README.md                    # This file
├── DEPLOYMENT.md                # Full deployment guide + Quick Suite challenges
├── SETUP_GUIDE.md               # Quick Suite space & chat agent setup
├── PREREQUISITES_DEPLOYMENT_GUIDE.md  # CID deployment (official AWS)
├── deploy/
│   ├── config.sh.example        # Configuration template (copy to config.sh)
│   ├── config.sh                # Your config (gitignored)
│   ├── deploy-cid.sh            # Automated deployment script
│   ├── copy-cur-to-cid.sh       # Copy existing CUR 2.0 into CID (backfill option)
│   └── README.md                # Deploy script documentation
└── LICENSE
```

## Architecture

```
Management Account          Data Collection Account
┌─────────────────────┐     ┌─────────────────────────────────┐
│ Cost Optimization   │     │ S3 (CUR, COH, FOCUS)             │
│ Hub (enabled)       │     │ Athena + Glue                    │
│                     │     │ QuickSight Dashboards            │
│ CUR 2.0 + COH +     │────▶│ CUDOS, CID, KPI, CORA, FOCUS     │
│ FOCUS Data Exports  │     │ Quick Suite Chat Agent          │
└─────────────────────┘     └─────────────────────────────────┘
```

## Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | **Start here** – Full install guide, Quick Suite permission challenges, troubleshooting |
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Quick Suite Space, Chat Agent, flows, sample prompts |
| [PREREQUISITES_DEPLOYMENT_GUIDE.md](./PREREQUISITES_DEPLOYMENT_GUIDE.md) | Step-by-step CID deployment (manual or automated) |
| [deploy/README.md](./deploy/README.md) | Deployment scripts, including [copy-cur-to-cid.sh](./deploy/copy-cur-to-cid.sh) for backfilling existing CUR 2.0 |

## Costs

Estimated monthly costs for the FinOps AI Assistant:

| Component | Est. Monthly Cost |
|-----------|--------------------|
| **Quick Suite Author Pro** (1 user) | $40 |
| **SPICE** (~40GB) | ~$15 (included with Author, or $0.38/GB) |
| **CID infrastructure** (S3, Athena, Glue, Lambda) | ~$5–15 |
| **Total** | **~$50–70/month** |

**Quick Suite subscription:** Configure your subscription in [Manage Quick Suite](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html). You must use **Enterprise edition** and provision at least one **Author Pro** user to access Chat Agents and generative AI features.

---

## AWS References

- [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)
- [Generative AI with CID and Quick Suite](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html)
- [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)
- [Cloud Intelligence Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/welcome.html)
- [Amazon Quick Suite pricing](https://aws.amazon.com/quicksight/pricing/)

## License

Apache License 2.0 – see [LICENSE](./LICENSE).
