#!/bin/bash
# Cloud Intelligence Dashboards - Automated Deployment
# Follows: https://docs.aws.amazon.com/guidance/latest/cloud-intelligence-dashboards/deployment-in-global-regions.html

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

deploy_step0() {
    log_info "Step 0: Enabling Cost Optimization Hub in Management account..."
    aws cost-optimization-hub update-enrollment-status \
        --status Active \
        --profile "${MANAGEMENT_PROFILE}" \
        --region "${AWS_REGION}" \
        --output json
    log_info "Step 0 complete. Cost Optimization Hub is now Active."
}

usage() {
    echo "Usage: $0 [step0|step1|step2|step3|all]"
    echo ""
    echo "  step0  - Enable Cost Optimization Hub in Management account (required for CORA)"
    echo "  step1  - Deploy destination stack in Data Collection account"
    echo "  step2  - Deploy source stack in Management account"
    echo "  step3  - Deploy CID dashboards in Data Collection account"
    echo "  all    - Run all steps in sequence (step0 → step1 → step2 → step3)"
    echo ""
    echo "Prerequisites:"
    echo "  - AWS CLI configured with management-account and data-collection-access-profile"
    echo "  - Cost Optimization Hub enabled (for CORA): https://console.aws.amazon.com/costmanagement/home#/cost-optimization-hub"
    echo "  - QuickSight signed up in Data Collection account (for step3)"
    echo "  - Set QUICKSIGHT_USERNAME in config.sh before running step3"
}

deploy_step1() {
    log_info "Step 1: Deploying destination stack in Data Collection account..."
    
    aws cloudformation create-stack \
        --profile "${DATA_COLLECTION_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "CID-DataExports-Destination" \
        --template-url "${DATA_EXPORTS_TEMPLATE}" \
        --parameters \
            ParameterKey=DestinationAccountId,ParameterValue="${DATA_COLLECTION_ACCOUNT_ID}" \
            ParameterKey=ManageCUR2,ParameterValue=yes \
            ParameterKey=ManageCOH,ParameterValue=yes \
            ParameterKey=ManageFOCUS,ParameterValue=yes \
            ParameterKey=ManageCarbon,ParameterValue=no \
            ParameterKey=SourceAccountIds,ParameterValue="${MANAGEMENT_ACCOUNT_ID}" \
            ParameterKey=ResourcePrefix,ParameterValue=cid \
            ParameterKey=EnableSCAD,ParameterValue=yes \
        --capabilities CAPABILITY_NAMED_IAM \
        --disable-rollback 2>/dev/null || {
            if aws cloudformation describe-stacks --profile "${DATA_COLLECTION_PROFILE}" --region "${AWS_REGION}" --stack-name "CID-DataExports-Destination" &>/dev/null; then
                log_warn "Stack CID-DataExports-Destination already exists. Use update-stack or delete and re-run."
            else
                log_error "Failed to create stack. Check AWS CLI and permissions."
                exit 1
            fi
        }
    
    log_info "Waiting for stack CID-DataExports-Destination to complete..."
    aws cloudformation wait stack-create-complete \
        --profile "${DATA_COLLECTION_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "CID-DataExports-Destination" 2>/dev/null || true
    
    log_info "Step 1 complete."
}

deploy_step2() {
    log_info "Step 2: Deploying source stack in Management account..."
    
    aws cloudformation create-stack \
        --profile "${MANAGEMENT_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "CID-DataExports-Source" \
        --template-url "${DATA_EXPORTS_TEMPLATE}" \
        --parameters \
            ParameterKey=DestinationAccountId,ParameterValue="${DATA_COLLECTION_ACCOUNT_ID}" \
            ParameterKey=ManageCUR2,ParameterValue=yes \
            ParameterKey=ManageCOH,ParameterValue=yes \
            ParameterKey=ManageFOCUS,ParameterValue=yes \
            ParameterKey=ManageCarbon,ParameterValue=no \
            ParameterKey=SourceAccountIds,ParameterValue="" \
            ParameterKey=ResourcePrefix,ParameterValue=cid \
            ParameterKey=EnableSCAD,ParameterValue=yes \
        --capabilities CAPABILITY_NAMED_IAM \
        --disable-rollback 2>/dev/null || {
            if aws cloudformation describe-stacks --profile "${MANAGEMENT_PROFILE}" --region "${AWS_REGION}" --stack-name "CID-DataExports-Source" &>/dev/null; then
                log_warn "Stack CID-DataExports-Source already exists."
            else
                log_error "Failed to create stack. Ensure Step 1 completed first."
                exit 1
            fi
        }
    
    log_info "Waiting for stack CID-DataExports-Source to complete..."
    aws cloudformation wait stack-create-complete \
        --profile "${MANAGEMENT_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "CID-DataExports-Source" 2>/dev/null || true
    
    log_info "Step 2 complete. Data delivery takes 24-48 hours (up to 72h)."
}

deploy_step3() {
    if [ -z "${QUICKSIGHT_USER}" ]; then
        log_error "QUICKSIGHT_USER must be set in config.sh. Get it from QuickSight console (person icon → top right)."
        exit 1
    fi
    
    log_info "Step 3: Deploying CID dashboards in Data Collection account..."
    
    aws cloudformation create-stack \
        --profile "${DATA_COLLECTION_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "Cloud-Intelligence-Dashboards" \
        --template-url "${CID_DASHBOARDS_TEMPLATE}" \
        --parameters \
            ParameterKey=QuickSightUser,ParameterValue="${QUICKSIGHT_USER}" \
            ParameterKey=DeployCUDOSv5,ParameterValue=yes \
            ParameterKey=DeployCostIntelligenceDashboard,ParameterValue=yes \
            ParameterKey=DeployKPIDashboard,ParameterValue=yes \
            ParameterKey=CURVersion,ParameterValue=2.0 \
            ParameterKey=PrerequisitesQuickSight,ParameterValue=yes \
            ParameterKey=PrerequisitesQuickSightPermissions,ParameterValue=yes \
        --capabilities CAPABILITY_NAMED_IAM \
        --disable-rollback 2>/dev/null || {
            if aws cloudformation describe-stacks --profile "${DATA_COLLECTION_PROFILE}" --region "${AWS_REGION}" --stack-name "Cloud-Intelligence-Dashboards" &>/dev/null; then
                log_warn "Stack Cloud-Intelligence-Dashboards already exists."
            else
                log_error "Failed to create stack. Ensure Step 1 and 2 completed. Check QuickSight is set up."
                exit 1
            fi
        }
    
    log_info "Waiting for stack Cloud-Intelligence-Dashboards (may take ~15 mins)..."
    aws cloudformation wait stack-create-complete \
        --profile "${DATA_COLLECTION_PROFILE}" \
        --region "${AWS_REGION}" \
        --stack-name "Cloud-Intelligence-Dashboards" 2>/dev/null || true
    
    log_info "Step 3 complete. Dashboards available in QuickSight."
}

# Main
case "${1:-}" in
    step0) deploy_step0 ;;
    step1) deploy_step1 ;;
    step2) deploy_step2 ;;
    step3) deploy_step3 ;;
    all)
        deploy_step0
        deploy_step1
        deploy_step2
        log_info "Waiting 30 seconds before Step 3..."
        sleep 30
        deploy_step3
        ;;
    *) usage; exit 1 ;;
esac
