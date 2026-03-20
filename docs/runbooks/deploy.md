# Deploy Runbook

## Stage Deploy
1. Merge approved PR into `stage`
2. GitHub Actions starts `Deploy Stage`
3. Review workflow logs
4. Confirm Terraform apply completed
5. Smoke test:
   - ALB reachable
   - Cognito auth path works
   - S3 static assets accessible
   - CloudWatch alarms healthy

## Production Deploy
1. Create release PR / merge to `main`
2. Validate changelog and version tag
3. Run production plan
4. Obtain approval in GitHub Environment
5. Apply production Terraform
6. Smoke test critical flows