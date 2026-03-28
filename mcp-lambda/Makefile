# FinOps Billing MCP Lambda – build and deploy
SAM_BUILD_DIR = .aws-sam/build
STACK_NAME = finops-billing-mcp

.PHONY: build deploy delete validate clean

build:
	sam build

deploy: build
	sam deploy --no-confirm-changeset --no-fail-on-empty-changeset \
		--stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--resolve-s3

delete:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)

validate:
	sam validate

clean:
	rm -rf $(SAM_BUILD_DIR)
	rm -rf .aws-sam

# After deploy, print the MCP URL for Quick Suite
url:
	@aws cloudformation describe-stacks --stack-name $(STACK_NAME) \
		--query "Stacks[0].Outputs[?OutputKey=='BillingMCPFunctionUrl'].OutputValue" --output text 2>/dev/null || echo "Stack not deployed. Run: make deploy"
