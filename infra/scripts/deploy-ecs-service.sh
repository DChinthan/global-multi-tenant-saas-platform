#!/usr/bin/env bash
# Forces a fresh ECS Fargate deployment for one service in this repo's
# cluster (naming matches infra/terraform/modules/compute/ecs.tf and
# ecr.tf: cluster "${project}-${env}-cluster", service
# "${project}-${env}-${service}-service", ECR repo "${project}-${env}-${service}"),
# waits for the service to reach steady state, then prunes untagged ECR
# images beyond the most recent N (the ECR lifecycle policy in
# modules/compute/ecr.tf already caps each repo at 20 images total; this
# trims dangling/untagged ones sooner and on-demand).
#
# See infra/scripts/Deploy-EcsService.ps1 for the AWS.Tools/PowerShell
# equivalent of this same operation.
set -euo pipefail

PROJECT="${PROJECT:-global-multi-tenant-saas-platform}"
ENVIRONMENT="${1:?Usage: deploy-ecs-service.sh <environment> <service> [keep-count]}"
SERVICE="${2:?Usage: deploy-ecs-service.sh <environment> <service> [keep-count]}"
KEEP_COUNT="${3:-5}"
REGION="${AWS_REGION:-us-east-1}"

CLUSTER="${PROJECT}-${ENVIRONMENT}-cluster"
ECS_SERVICE="${PROJECT}-${ENVIRONMENT}-${SERVICE}-service"
ECR_REPO="${PROJECT}-${ENVIRONMENT}-${SERVICE}"

echo "==> Forcing new deployment: cluster=$CLUSTER service=$ECS_SERVICE"
aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$ECS_SERVICE" \
  --force-new-deployment \
  --region "$REGION" \
  --query 'service.{status:status,desired:desiredCount,running:runningCount}' \
  --output table

echo "==> Waiting for service to reach steady state (can take a few minutes)..."
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$REGION"

echo "==> Deployment stable."

echo "==> Pruning untagged images in $ECR_REPO older than the most recent $KEEP_COUNT..."
IMAGE_DIGESTS=$(aws ecr describe-images \
  --repository-name "$ECR_REPO" \
  --region "$REGION" \
  --filter tagStatus=UNTAGGED \
  --query "sort_by(imageDetails,& imagePushedAt)[:-${KEEP_COUNT}].imageDigest" \
  --output text)

if [ -z "$IMAGE_DIGESTS" ]; then
  echo "No untagged images to prune."
  exit 0
fi

for DIGEST in $IMAGE_DIGESTS; do
  echo "  deleting $DIGEST"
  aws ecr batch-delete-image \
    --repository-name "$ECR_REPO" \
    --region "$REGION" \
    --image-ids imageDigest="$DIGEST" >/dev/null
done

echo "==> Done."
