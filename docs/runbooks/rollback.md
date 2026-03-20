# Rollback Runbook

## Infra Rollback
1. Identify bad merge / release tag
2. Revert the offending PR or commit
3. Open rollback PR
4. Ensure CI checks pass
5. Re-run Terraform plan and verify destructive actions
6. Apply reverted configuration

## App Rollback
1. Redeploy previous stable artifact or image tag
2. Validate health checks
3. Confirm logs and alarms normalize

## Emergency Controls
- Disable feature flags if available
- Scale down unhealthy service
- Fail traffic back to stable target group / environment
- Restore from backup only if rollback is impossible