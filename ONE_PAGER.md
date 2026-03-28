0## FinOps AI Assistant – One‑Pager

### 1. What This Is

- **Goal**: Give FinOps, engineering, and leadership a generative‑AI assistant that can answer natural‑language questions about AWS spend, optimization opportunities, security, and operations.
- **Built on**: AWS **Cloud Intelligence Dashboards (CID)** + **Amazon Quick Suite** (QuickSight Enterprise + Author Pro).
- **Outcome**: Users chat with a `CID Operations Advisor` agent that reads from your CID dashboards and returns data‑backed, drill‑downable answers.

### 2. What You Get

- **Dashboards (CID)**:
  - **CUDOS v5** – cost and usage with resource‑level detail.
  - **Cost Intelligence Dashboard** – executive roll‑ups and KPIs.
  - **KPI Dashboard** – modernization metrics (Spot, Graviton, etc.).
  - **CORA** – Cost Optimization Recommended Actions.
  - **FOCUS Dashboard** – FinOps Cost and Usage Specification views.
- **AI Layer (Quick Suite)**:
  - **CID Dashboards Space** – curated space with all CID dashboards.
  - **CID Operations Advisor Chat Agent** – generative AI assistant over that space.
  - **Optional Flows** – repeatable workflows (e.g., anomaly analysis, top 5 savings).

### 3. Architecture (High‑Level)

**Accounts**

- **Management (Payer) Account**
  - Owns consolidated billing.
  - Produces **CUR 2.0**, **Cost Optimization Hub**, and **FOCUS** data exports.
- **Data Collection Account**
  - Centralizes cost/operations data in **S3**.
  - Runs **Athena + Glue** for querying.
  - Hosts **Quick Suite** (QuickSight Enterprise, SPICE, dashboards, Chat Agent).

**Data & Control Flow**

```text
Management Account                          Data Collection Account
--------------------                        -------------------------
CUR 2.0 Data Exports   ─────────────┐
Cost Optimization Hub   ────────────┼─▶  S3 (CID Data Exports bucket)
FOCUS Exports           ────────────┘       │
                                            ▼
                                      Glue + Athena
                                            │
                                            ▼
                                  CID Dashboards (CUDOS, CID, KPI, CORA, FOCUS, …)
                                            │
                                            ▼
                              Quick Suite Space (CID Dashboards Space)
                                            │
                                            ▼
                              CID Operations Advisor Chat Agent
                                  ▲
                                  │
                        End‑users  FinOps, Eng, Leadership)
```

### 4. Key Requirements (Non‑Negotiable)

- **Quick Suite edition**: **Enterprise** only; Standard does **not** support Chat Agents/Flows.
- **User type**: At least one **Author Pro** user in the Data Collection account.
- **SPICE**: ~**40 GB** recommended for CID datasets.
- **Permissions**:
  - CloudFormation, CUR/Data Exports, S3, Glue, Athena, QuickSight, Lambda.
  - QuickSight service role configured for S3 + Athena access.

### 5. How to Deploy (Choices)

- **Option A – Official AWS flow (console‑driven)**
  - Use AWS “Deployment in Global Regions” guide (Step 1–3) to:
    - Create Data Collection destination stack.
    - Configure Management (Payer) stack for CUR 2.0 + exports.
    - Deploy CID dashboards into Quick Suite.
  - Then follow `SETUP_GUIDE.md` to create the **space** + **CID Operations Advisor** chat agent.

- **Option B – Scripted deployment (`deploy/deploy-cid.sh`)**
  - Configure `config.sh` with account IDs and **QuickSight username only** (no `default/` prefix).
  - Run:
    - `step0` – enable Cost Optimization Hub.
    - `step1` – Data Collection: destination resources.
    - `step2` – Management: CUR + exports + replication.
    - `step3` – Data Collection: dashboards into Quick Suite.
  - Optional: `copy-cur-to-cid.sh` to backfill existing CUR 2.0 to CID bucket.

### 6. Typical User Journeys

- **FinOps lead**: “Where did my AWS spend increase the most last week, and why?”  
  → Agent pulls from CUDOS/CID, highlights services/accounts, quantifies change, and suggests dashboards to drill into.

- **Engineering manager**: “Give me the top 5 quick wins to reduce compute cost this month.”  
  → Agent reads CORA/FOCUS, ranks rightsizing/idle/spot actions, and returns estimated savings.

- **Security/ops**: “Which accounts have the highest operational or security risk right now?”  
  → Agent combines TAO/operations dashboards (if deployed) and surfaces high‑risk areas with links.

### 7. Where to Go Deeper

- **Quick hands‑on**: `README.md` (Quick Start section).
- **Full deployment details + real‑world errors**: `DEPLOYMENT.md`.
- **Official AWS‑style deployment**: `PREREQUISITES_DEPLOYMENT_GUIDE.md`.
- **Space + Chat Agent config**: `SETUP_GUIDE.md`.
- **Automation scripts + backfill**: `deploy/README.md`.

