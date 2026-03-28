"""
AWS Billing MCP Lambda Gateway

Exposes AWS Cost Explorer, Budgets, and Cost Optimization Hub as MCP tools
for Amazon Quick Suite and other MCP clients. Uses streamable HTTP transport.
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta
from typing import Any, Mapping

import boto3
from awslabs.mcp_lambda_handler import MCPLambdaHandler

mcp = MCPLambdaHandler(
    name="finops-billing-mcp",
    version="1.0.0",
)


def _ce_client():
    return boto3.client("ce", region_name="us-east-1")


def _budgets_client():
    return boto3.client("budgets", region_name="us-east-1")


def _coh_client():
    return boto3.client("cost-optimization-hub", region_name="us-east-1")


@mcp.tool()
def get_cost_and_usage(
    time_period_days: int = 30,
    granularity: str = "DAILY",
    group_by_dimension: str | None = "SERVICE",
    metric: str = "UnblendedCost",
) -> str:
    """
    Get AWS cost and usage for a time period. Use for spend trends, service breakdowns,
    and month-over-month analysis. Granularity: DAILY | MONTHLY | HOURLY.
    group_by_dimension: SERVICE | LINKED_ACCOUNT | REGION | etc. (optional).
    """
    client = _ce_client()
    end = datetime.utcnow().date()
    start = end - timedelta(days=time_period_days)
    params: dict[str, Any] = {
        "TimePeriod": {
            "Start": start.isoformat(),
            "End": end.isoformat(),
        },
        "Granularity": granularity,
        "Metrics": [metric],
    }
    if group_by_dimension:
        params["GroupBy"] = [{"Type": "DIMENSION", "Key": group_by_dimension}]
    response = client.get_cost_and_usage(**params)
    return json.dumps(response, default=str)


@mcp.tool()
def get_cost_forecast(
    forecast_days: int = 30,
    metric: str = "UNBLENDED_COST",
) -> str:
    """
    Get forecasted AWS costs for the next N days. Helps with budget planning.
    """
    client = _ce_client()
    end = datetime.utcnow().date() + timedelta(days=forecast_days)
    start = datetime.utcnow().date()
    response = client.get_cost_forecast(
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Metric=metric,
        Granularity="DAILY",
    )
    return json.dumps(response, default=str)


@mcp.tool()
def get_dimension_values(
    dimension: str = "SERVICE",
    time_period_days: int = 30,
) -> str:
    """
    Get dimension values (e.g. service names, regions) for cost data.
    dimension: SERVICE | LINKED_ACCOUNT | REGION | etc.
    """
    client = _ce_client()
    end = datetime.utcnow().date()
    start = end - timedelta(days=time_period_days)
    response = client.get_dimension_values(
        TimePeriod={"Start": start.isoformat(), "End": end.isoformat()},
        Dimension=dimension,
    )
    return json.dumps(response, default=str)


@mcp.tool()
def describe_budgets(account_id: str | None = None) -> str:
    """
    List AWS Budgets and their current status (actual vs forecasted vs limit).
    account_id: optional; if not set uses the caller's account.
    """
    client = _budgets_client()
    kwargs: dict[str, Any] = {}
    if account_id:
        kwargs["AccountId"] = account_id
    response = client.describe_budgets(**kwargs)
    return json.dumps(response, default=str)


@mcp.tool()
def list_recommendation_summaries(
    group_by: str = "RecommendationType",
) -> str:
    """
    List Cost Optimization Hub recommendation summaries (rightsizing, savings plans, etc.).
    group_by: RecommendationType | ResourceType | etc.
    """
    client = _coh_client()
    response = client.list_recommendation_summaries(groupBy=group_by)
    return json.dumps(response, default=str)


@mcp.tool()
def get_anomalies(
    time_period_days: int = 30,
    monitor_arn: str | None = None,
) -> str:
    """
    Get cost anomalies detected by AWS Cost Anomaly Detection.
    monitor_arn: optional anomaly monitor ARN to filter.
    """
    client = _ce_client()
    end = datetime.utcnow().date()
    start = end - timedelta(days=time_period_days)
    params: dict[str, Any] = {
        "DateInterval": {
            "Start": start.isoformat(),
            "End": end.isoformat(),
        },
    }
    if monitor_arn:
        params["MonitorArn"] = monitor_arn
    response = client.get_anomalies(**params)
    return json.dumps(response, default=str)


def lambda_handler(event: dict, context: object) -> dict:
    """
    AWS Lambda entrypoint for MCP over HTTP (Lambda Function URL / API Gateway).

    Notes:
    - Some clients probe endpoints with GET/OPTIONS during setup. We return a friendly
      response for GET and a no-op for OPTIONS.
    - Normalize Content-Type for JSON-RPC POST calls to avoid strict media-type checks.
    - Respond to /.well-known/mcp for MCP discovery (Quick Suite and other clients).
    """

    def _headers() -> dict[str, str]:
        raw: Mapping[str, Any] = event.get("headers") or {}
        # Normalize to a simple lower-case key dict.
        return {str(k).lower(): str(v) for k, v in raw.items() if k is not None}

    def _method() -> str:
        # API Gateway v2 / Function URL
        rc = event.get("requestContext") or {}
        http = rc.get("http") or {}
        m = http.get("method") or event.get("httpMethod") or "POST"
        return str(m).upper()

    def _path() -> str:
        return (event.get("rawPath") or event.get("requestContext", {}).get("http", {}).get("path") or "/").rstrip("/") or "/"

    method = _method()
    path = _path()
    headers = _headers()
    has_body = bool(event.get("body"))

    # Debug: helps trace Quick Suite requests in CloudWatch (filter: [MCP])
    print(f"[MCP] {method} {path} body={has_body}")

    # MCP discovery endpoint (e.g. Quick Suite)
    if method == "GET" and path == "/.well-known/mcp":
        proto = headers.get("x-forwarded-proto", "https")
        host = headers.get("host", "")
        base = f"{proto}://{host}" if host else "https://unknown"
        mcp_endpoint = base.rstrip("/") + "/mcp"
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(
                {
                    "mcp_version": "2024-11-05",
                    "endpoints": {"streamable_http": mcp_endpoint},
                    "capabilities": {"tools": {"list": True, "call": True}, "resources": {"list": True, "read": True}},
                    "server_info": {"name": "finops-billing-mcp", "version": "1.0.0"},
                }
            ),
        }

    if method in {"GET", "HEAD"}:
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(
                {
                    "name": "finops-billing-mcp",
                    "version": "1.0.0",
                    "message": "MCP endpoint is ready. Send JSON-RPC requests via POST to /mcp.",
                    "mcp_endpoint": "/mcp",
                }
            ),
        }

    if method == "OPTIONS":
        return {
            "statusCode": 204,
            "headers": {
                "access-control-allow-origin": "*",
                "access-control-allow-methods": "GET,POST",
                "access-control-allow-headers": "*",
            },
            "body": "",
        }

    # POST without body: MCP library would raise KeyError. Quick Suite may send empty POST during creation.
    # Return a minimal valid MCP-style response so creation succeeds; real tool calls will include a body.
    if not event.get("body"):
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": None,
                    "result": {
                        "capabilities": {"tools": {"listChanged": False}, "resources": {"subscribeChanged": False}},
                        "serverInfo": {"name": "finops-billing-mcp", "version": "1.0.0"},
                    },
                }
            ),
        }

    content_type = headers.get("content-type", "")
    if "application/json" in content_type.lower():
        # Normalize charset variants to plain application/json for strict parsers.
        event.setdefault("headers", {})
        event["headers"]["Content-Type"] = "application/json"
        event["headers"]["content-type"] = "application/json"
    elif event.get("body"):
        # If a body exists but Content-Type is missing, assume JSON.
        event.setdefault("headers", {})
        event["headers"]["Content-Type"] = "application/json"
        event["headers"]["content-type"] = "application/json"

    return mcp.handle_request(event, context)
