# FinOps AI Assistant

Deploy a **Generative AI FinOps Assistant** using [AWS Cloud Intelligence Dashboards (CID)](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/) and [Amazon Quick Suite](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html). Ask natural language questions about your AWS costs, optimization opportunities, security, and operations.

## What You Get

- **CUDOS v5** – Cost & usage insights with resource-level drill-down
- **Cost Intelligence Dashboard** – Executive-friendly cost management
- **KPI Dashboard** – Modernization goals (Spot, Graviton, etc.)
- **CORA** – Cost Optimization Recommended Actions
- **FOCUS Dashboard** – FinOps Cost and Usage Specification
- **Quick Suite Chat Agent** – AI-powered FinOps advisor across all dashboards

## Quick Start

### 1. Prerequisites

- Two AWS accounts: **Management (Payer)** and **Data Collection**
- [AWS CLI](https://aws.amazon.com/cli/) configured with profiles for both accounts
- [QuickSight](https://quicksight.aws.amazon.com/) signed up in Data Collection account (~40GB SPICE)

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
# Edit config.sh with your account IDs and QuickSight user

./deploy-cid.sh step0   # Enable Cost Optimization Hub (if not done above)
./deploy-cid.sh step1   # Data Collection account – destination
./deploy-cid.sh step2   # Management account – source + CUR
./deploy-cid.sh step3   # Data Collection account – dashboards

# Or run all: ./deploy-cid.sh all
```

### 4. Configure Quick Suite Chat Agent

Follow [SETUP_GUIDE.md](./SETUP_GUIDE.md) to create the CID Operations Advisor chat agent in Quick Suite.

## Project Structure

```
├── README.md                    # This file
├── SETUP_GUIDE.md               # Quick Suite space & chat agent setup
├── PREREQUISITES_DEPLOYMENT_GUIDE.md  # Full CID deployment guide
├── deploy/
│   ├── config.sh.example        # Configuration template (copy to config.sh)
│   ├── config.sh                # Your config (gitignored)
│   ├── deploy-cid.sh            # Automated deployment script
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
| [SETUP_GUIDE.md](./SETUP_GUIDE.md) | Quick Suite Space, Chat Agent, flows, sample prompts |
| [PREREQUISITES_DEPLOYMENT_GUIDE.md](./PREREQUISITES_DEPLOYMENT_GUIDE.md) | Step-by-step CID deployment (manual or automated) |
| [deploy/README.md](./deploy/README.md) | Automated deployment script usage |

## AWS References

- [Generative AI with CID and Quick Suite](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html)
- [Deployment in Global Regions](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html)
- [Cloud Intelligence Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/welcome.html)

## License

Apache License 2.0 – see [LICENSE](./LICENSE).
