# FinOps Billing MCP Lambda Gateway

A **serverless MCP (Model Context Protocol) server** that exposes AWS Billing and Cost Management data (Cost Explorer, Budgets, Cost Optimization Hub, Anomaly Detection) over HTTP. Use it with **Amazon Quick Suite** so your Chat Agents can answer cost and FinOps questions using live AWS data.

## Architecture

```
Quick Suite Chat Agent  →  MCP over HTTP  →  Lambda (this project)  →  AWS Cost APIs
                                    ↑
                          API Gateway HTTP API
                          (public HTTPS endpoint)
```

- **Quick Suite** connects to the **API Gateway HTTP API** endpoint as a remote MCP server (Integrations → MCP).
- The Lambda runs the **MCP Lambda Handler** and implements **tools** that call AWS Cost Explorer, Budgets, and Cost Optimization Hub via the Lambda execution role.
- No long-lived credentials; the Lambda uses its IAM role.

## MCP Tools Exposed

| Tool | Description |
|------|-------------|
| `get_cost_and_usage` | Cost and usage for a time period (by service, account, region, etc.) |
| `get_cost_forecast` | Cost forecast for the next N days |
| `get_dimension_values` | Dimension values (e.g. service names, regions) for filtering |
| `describe_budgets` | List budgets and their status (actual vs limit) |
| `list_recommendation_summaries` | Cost Optimization Hub recommendation summaries |
| `get_anomalies` | Cost anomaly detection results |

## Prerequisites

- **AWS CLI** configured with credentials that can create Lambda, IAM, and CloudFormation resources.
- **AWS SAM CLI** installed ([Install SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)).
- **Python 3.12** (for local testing; SAM build uses it to create the deployment package).
- **Cost Explorer** enabled in the account ([Enable Cost Explorer](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)).
- (Optional) **Cost Optimization Hub** enabled for recommendation tools.

## Deployment

### 1. Build and deploy with SAM

From the `mcp-lambda` directory:

```bash
cd mcp-lambda
sam build
sam deploy --guided
```

- When prompted:
  - **Stack name**: `finops-billing-mcp` (or your choice).
  - **AWS Region**: e.g. `us-east-1`.
  - **Confirm changeset**: Yes.
  - **Allow SAM CLI IAM role creation**: Yes.
  - **Disable rollback**: No (default).
  - **Save arguments to configuration file**: Yes (creates `samconfig.toml` for future deploys).

### 2. Get the MCP endpoint URL

After a successful deploy, the stack output **BillingMCPApiUrl** is your MCP endpoint base URL:

```bash
aws cloudformation describe-stacks \
  --stack-name finops-billing-mcp \
  --query "Stacks[0].Outputs[?OutputKey=='BillingMCPApiUrl'].OutputValue" \
  --output text
```

Or use the Makefile:

```bash
make deploy
make url
```

Example base URL: `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com`

Two ways to connect Quick Suite (try in this order if one fails):

1. **Discovery URL** (recommended): paste the **base URL** so Quick Suite can discover the MCP endpoint via `GET /.well-known/mcp`:
   - `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com`
2. **Direct MCP endpoint**: paste the URL with `/mcp`:
   - `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/mcp`

## Connect to Amazon Quick Suite

1. Open **Amazon Quick Suite** → **Integrations** → **Add** (+).
2. Choose **MCP** as the integration type.
3. **MCP server endpoint**: paste either the base URL (e.g. `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com`) so Quick Suite can use discovery, or the direct endpoint `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/mcp`.
4. **Authentication**: Quick Suite supports OAuth or service-to-service. For a first test, you can use the endpoint with **AuthType: NONE** (the template uses open URL; restrict with IAM or a custom authorizer in production).
5. Complete the wizard; a **knowledge base** is created from the MCP integration.
6. In your **Chat Agent** (e.g. CID Operations Advisor), add this MCP-based knowledge source (or action connector) so the agent can call the billing tools.

See [Amazon Quick – MCP integration](https://docs.aws.amazon.com/quicksuite/latest/userguide/mcp-integration.html) for details.

## Troubleshooting & logs when integration fails

### 1. Quick Suite side (where the failure is shown)

Quick Suite does **not** expose a dedicated, customer-visible log group just for “MCP integration creation failed.” Use these places to get as much info as possible:

- **In the UI**: When MCP integration creation fails, Quick Suite shows a short message (e.g. “Creation failed”, “Connector creation is not completed”). Check for a **details** or **See more** link and copy the **full error text**.
- **CloudTrail (Quick Suite account)**  
  Quick/QuickSight API calls are recorded in **CloudTrail** in the account where Quick is set up.  
  1. **CloudTrail** → **Event history** (same region as Quick, e.g. `us-east-1`).  
  2. Filter by **Event name** (e.g. `CreateIntegration`, `RegisterIntegration`, or similar) or **User name** / **Time range** when you clicked Create.  
  3. Open the event and check **Error code** and **Error message**; they sometimes give a reason (e.g. timeout, validation, internal error).
- **CloudWatch (Quick Suite account)**  
  There is no documented “MCP connector creation” log group. For **action execution** (after an integration exists), the troubleshooting doc says to “Review CloudWatch logs”—that usually means the **backend** (e.g. your MCP Lambda). In CloudWatch, you can search log groups for names containing `quicksight`, `quick`, or `qbusiness` and look for recent errors; integration-creation failures are not guaranteed to appear there.
- **AWS Support**  
  If the UI and CloudTrail don’t show a clear reason, open an **AWS Support** case (Support Center in the Quick/QuickSight account). Ask specifically for “logs or error details for failed MCP integration creation in Amazon Quick.” Support can see server-side logs that are not exposed in the console.

### 2. Your MCP endpoint (Lambda + API Gateway) – best place to debug

The **Lambda** that backs your MCP endpoint logs every request (and any Python errors) to **CloudWatch Logs**. Use this to see whether Quick Suite is calling your API and what your server returns.

**Log group name:**
```text
/aws/lambda/finops-billing-mcp
```

**In AWS Console:**
1. Open **CloudWatch** → **Log groups** (in the same account and region as the stack, e.g. `us-east-1`).
2. Open the log group **`/aws/lambda/finops-billing-mcp`**.
3. Open the latest **Log stream** (each stream is one invocation or a short time window).
4. Reproduce the failure in Quick Suite (click Create again), then refresh the stream to see new events: request payload, response, and any tracebacks.

**From CLI (linked account profile, same region as deploy):**
```bash
# List latest log streams
aws logs describe-log-streams \
  --log-group-name /aws/lambda/finops-billing-mcp \
  --order-by LastEventTime \
  --descending \
  --max-items 5 \
  --profile linked-account-profile \
  --region us-east-1

# Tail recent events (replace STREAM_NAME with a stream name from above)
aws logs get-log-events \
  --log-group-name /aws/lambda/finops-billing-mcp \
  --log-stream-name "STREAM_NAME" \
  --profile linked-account-profile \
  --region us-east-1
```

**What to look for:** When you retry creating the MCP integration in Quick Suite, you should see one or more invocations in this log group. If you see **no new invocations**, Quick Suite is not reaching your API (e.g. wrong URL, network/firewall, or discovery failure). If you see **invocations with 4xx/5xx or Python errors**, the log events will show the exact error and response body.

### 3. What we found in your account (steps 2–4)

- **CloudTrail (Step 2):** In account `010928194325`, `CreateActionConnector` for type `MODEL_CONTEXT_PROTOCOL` returns **status 202** with **creationStatus: CREATION_IN_PROGRESS** and **creationStatusInternal: AUTH_COMPLETE**. So the create API succeeds; the failure happens later when Quick Suite tries to use the connector (e.g. discover tools or call the MCP endpoint). No error code is in CloudTrail for the create call itself.
- **CloudWatch (Step 3):** No Quick/QuickSight-specific log groups in this account; integration creation failures are not written to a customer-visible log group.
- **Lambda logs (Step 4):** In `/aws/lambda/finops-billing-mcp` we saw:
  - **KeyError: 'body'** – A request reached the Lambda with no `body` in the event (e.g. GET or OPTIONS). The MCP library then crashes when parsing the body. Quick Suite may be sending a GET to the MCP URL; we already return 200 for GET on `/` and `/.well-known/mcp`, but if it GETs `/mcp` without a body, the handler still passes the event to the library and it can throw. Ensuring GET/HEAD to `/mcp` return a safe response (or ensuring the library never sees a missing body) would avoid this.
  - **list_recommendation_summaries** – Parameter error: the AWS API expects **`groupBy`** (camelCase); the tool was sending **`GroupBy`**. This is fixed in the handler so the tool works when clients call it.

**Next step:** Try creating the MCP integration again. If it still fails, run `aws logs tail /aws/lambda/finops-billing-mcp --follow --profile linked-account-profile --region us-east-1` and trigger the create; check whether any request shows **KeyError: 'body'** (meaning Quick Suite is hitting the endpoint in a way that has no body).

### 4. Optional: API Gateway access logs

To log every HTTP request/response (status code, latency) at the API Gateway layer, you can enable [HTTP API access logging](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-logging.html) to a CloudWatch log group. That shows whether a request reached API Gateway and what status was returned, before it hits Lambda.

## Security and production

- The default template uses an **open API Gateway endpoint** (no auth) so Quick Suite can connect easily. For production:
  - Add **JWT authorizer** (OAuth) on API Gateway, or
  - Use **AWS_IAM** authorization on API Gateway and restrict invocation to your IAM principals.
- Restrict **CORS** in `template.yaml` to your Quick Suite / allowed origins instead of `*` if needed.
- The Lambda role has least-privilege for **ce**, **budgets**, and **cost-optimization-hub**; add other actions only if you add more tools.

## Cost

- **Lambda**: Pay per request and duration (typically low for chat-driven usage).
- **Cost Explorer / Budgets / COH**: Normal API costs apply; no extra charge for the MCP layer.

## Development

- **Handler**: `handler.py` – defines MCP tools and uses `awslabs.mcp_lambda_handler`.
- **Dependencies**: `requirements.txt` (mcp-lambda-handler, boto3).
- **Template**: `template.yaml` – Lambda, API Gateway HTTP API, IAM.

To add a tool: add a `@mcp.tool()` function in `handler.py` and, if it calls new APIs, extend the Lambda `Policies` in `template.yaml`.

## References

- [Amazon Quick – MCP integration](https://docs.aws.amazon.com/quicksuite/latest/userguide/mcp-integration.html)
- [AWS Billing and Cost Management MCP Server (awslabs)](https://awslabs.github.io/mcp/servers/billing-cost-management-mcp-server/)
- [MCP Lambda Handler (PyPI)](https://pypi.org/project/awslabs.mcp-lambda-handler/)
- [Enable Cost Explorer](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)
