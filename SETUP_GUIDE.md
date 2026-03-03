# FinOps AI Assistant – CID + Quick Suite Setup Guide

Step-by-step checklist for setting up the Generative AI FinOps Assistant using Cloud Intelligence Dashboards (CID) and Amazon Quick Suite.

---

## Prerequisites

Before starting, ensure you have:

- [ ] **Cost Optimization Hub enabled** (Management account) – Required for CORA dashboard:
  ```bash
  aws cost-optimization-hub update-enrollment-status --status Active --profile management-account --region us-east-1
  ```
  Or run `./deploy/deploy-cid.sh step0` if using the automated deploy script.

- [ ] **AWS Account** with appropriate permissions
- [ ] **CID Dashboard(s) deployed** – See **[PREREQUISITES_DEPLOYMENT_GUIDE.md](./PREREQUISITES_DEPLOYMENT_GUIDE.md)** for step-by-step deployment of:
  - **CUDOS Dashboard v5** (cost & usage insights)
  - **CORA** (Cost Optimization Recommended Actions)
  - **Trusted Advisor Organizational (TAO)** View
  - **FOCUS Dashboard** (FinOps specification)
- [ ] **Quick Suite Enterprise** with at least one **Author Pro** user  
  - Chat Agents, Flows, and generative AI are Enterprise-only; Standard edition does not support them  
  - [Managing users in Amazon QuickSight](https://docs.aws.amazon.com/quicksight/latest/user/managing-users.html)  
  - [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html)

> **Costs:** Author Pro is ~$40/user/month. Review [Configure Amazon Quick Suite subscriptions](https://docs.aws.amazon.com/quicksuite/latest/userguide/managing-qbs-subscriptions.html) and [Amazon QuickSight pricing](https://aws.amazon.com/quicksight/pricing/). See project [README Costs section](README.md#costs).

---

## Part 1: Create a Space with CID Dashboards

| Step | Action | Status |
|------|--------|--------|
| 1 | Open **Amazon Quick Suite** console | ☐ |
| 2 | Select **Spaces** from the navigation menu | ☐ |
| 3 | Click **Create space** | ☐ |
| 4 | Configure space: | |
| | • **Name:** `CID Dashboards Space` | ☐ |
| | • **Description:** `Comprehensive knowledge base for all Cloud Intelligence Dashboards` | ☐ |
| 5 | Under **Dashboards**, click **Add Dashboards** | ☐ |
| 6 | Select your deployed CID dashboards | ☐ |
| 7 | Click **Add** | ☐ |
| 8 | Verify all dashboards appear in the space | ☐ |

---

## Part 2: Create & Configure the CID Chat Agent

### 2.1 Create the Agent

| Step | Action | Status |
|------|--------|--------|
| 1 | In Quick Suite console, select **Chat Agents** | ☐ |
| 2 | Click **Create Chat Agent** | ☐ |
| 3 | When the prompt box appears, click **Skip** | ☐ |

### 2.2 Basic Settings

| Field | Value |
|-------|-------|
| **Agent name** | `CID Operations Advisor` |
| **Description** | `Customer CID dashboard advisor for cost, security, and operations analysis` |

### 2.3 Agent Identity

Paste into the **Agent Identity** field:

```
You are a CID Operations Advisor specializing in AWS Cloud Intelligence Dashboards with deep expertise in cloud operations, cost optimization, FinOps, performance, security, and resiliency. You help organizations analyze cloud usage, costs, security, resiliency and operations by answering questions about their CID dashboards data. You provide clear, actionable insights for business operations, always grounding your responses in actual data from the available dashboards.
```

### 2.4 Persona Instructions

Copy the full Persona Instructions from the [AWS documentation](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html) or use a condensed version. Key sections include:

- Multi-Dashboard Analysis Approach
- Dashboard Integration Strategy (FinOps, Operations, Security, Resiliency)
- Enhanced Response Framework
- Operational Boundaries
- Success Metrics Focus

### 2.5 Communication Style

| Setting | Value |
|---------|-------|
| **Tone** | `Professional, direct, and business-focused. Use clear language appropriate for business operations.` |
| **Response Format** | `- Always provide dashboard quicklinks when referencing data`<br>`- Include time context (e.g., "Last 30 days", "Previous month")`<br>`- Quantify impact in both absolute costs and percentages`<br>`- Cross-reference related findings across dashboards`<br>`- Escalate critical security or cost issues immediately`<br>`- Offer drill-down suggestions for deeper analysis`<br>`- Provide specific data points from dashboards` |
| **Length** | `Be concise for simple queries. Provide detailed analysis with multiple data points when asked about trends, comparisons, or recommendations.` |

### 2.6 Link Knowledge Sources

| Step | Action | Status |
|------|--------|--------|
| 1 | Scroll to **Knowledge sources** section | ☐ |
| 2 | Click **Link spaces** | ☐ |
| 3 | Select your **CID Dashboards Space** | ☐ |
| 4 | Click **Add** or **Link** | ☐ |

### 2.7 Launch

| Step | Action | Status |
|------|--------|--------|
| 1 | Verify all configuration is correct | ☐ |
| 2 | Click **Launch Chat Agent** | ☐ |
| 3 | Test with sample prompts (see Part 4) | ☐ |

---

## Part 3: Optional – Create Automated Flows

### Flow 1: Cost Anomaly Investigation & Action

Automatically detects cost spikes and generates action plans.

| Method | Steps |
|--------|-------|
| **NLP** | Flows → Create Flow → Generate → Enter flow description from [docs](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html) → Generate Flow |
| **Manual** | Flows → Create Flow → Create a blank flow → Add steps: Text Input (Alert Threshold), Text Input (Analysis Time Period), Dashboard (CUDOS), Reasoning Group, Web Search, Analysis steps |

### Flow 2: Top 5 Cost Optimization Quick Wins

Identifies top 5 cost optimization opportunities with maximum savings and minimal effort.

| Method | Steps |
|--------|-------|
| **NLP** | Flows → Create Flow → Generate → Enter flow description from docs → Generate Flow |
| **Manual** | Create blank flow → Add: Dashboard (CUDOS), Rank Opportunities, Top 5 Selection reasoning group, Implementation Guidance, Final Report |

---

## Part 4: Test Your Agent – Sample Prompts

### FinOps
- *What are my top optimization opportunities for S3?*
- *What are my savings opportunities with terminating idle and rightsizing underutilized resources?*
- *Show me services which increased spend and usage last week*

### Operations
- *Show me the most critical operational risks*
- *Analyze upcoming health events and their business impact*
- *Show me support top services and top topics for which my organization opens support cases*

### Resilience
- *Show me single AZ resources*
- *Show me the most critical resilience and operational risks*

### Security
- *Show me top accounts with non compliant resources*
- *Show me the most critical security risks*

### Dashboard Discovery
- *Which dashboards provide me resilience related reports?*
- *Which dashboards provide details about idle resources and cloud waste?*

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| Agent can't access dashboard data | Verify the CID Dashboards Space is linked in Knowledge sources |
| No responses or generic answers | Ensure dashboards are deployed and contain data; include time ranges in prompts |
| Permission errors | Confirm Quick Suite user has Author Pro or Reader Pro |
| Flows not triggering | Verify threshold values, dashboard connections, and flow run mode |

---

## Quick Reference Links

- [AWS CID Generative AI Documentation](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/generative-ai.html)
- [Cloud Intelligence Dashboards](https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/welcome.html)
- [Amazon QuickSight Pricing](https://aws.amazon.com/quicksight/pricing/)
- [Managing QuickSight Users](https://docs.aws.amazon.com/quicksight/latest/user/managing-users.html)

---

> **Important:** This solution uses generative AI as a decision-support tool. Always validate AI-generated recommendations against your business requirements and AWS best practices.
