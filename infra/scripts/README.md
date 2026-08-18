# Operational Scripts

Standalone automation scripts that operate against real resource names from
this repo's Terraform (`infra/terraform/modules/compute/ecs.tf` and
`ecr.tf`), outside of the GitHub Actions workflows in `.github/workflows/`.

| Script | Purpose |
|---|---|
| [`deploy-ecs-service.sh`](deploy-ecs-service.sh) | Bash + AWS CLI: force a new ECS deployment for one service, wait for steady state, prune old untagged ECR images |
| [`Deploy-EcsService.ps1`](Deploy-EcsService.ps1) | PowerShell + [AWS Tools for PowerShell](https://docs.aws.amazon.com/powershell/) (`AWS.Tools.ECS`, `AWS.Tools.ECR`): the same operation, kept side-by-side as a working Bash-vs-PowerShell comparison |

## Usage

```bash
# Bash
./deploy-ecs-service.sh dev app
./deploy-ecs-service.sh stage app5-fileservice 3   # keep 3 untagged images instead of the default 5
```

```powershell
# PowerShell (requires AWS.Tools.ECS + AWS.Tools.ECR - see script header)
./Deploy-EcsService.ps1 -Environment dev -Service app
./Deploy-EcsService.ps1 -Environment stage -Service app5-fileservice -KeepCount 3
```

Both scripts assume the target environment's Terraform has already been
applied at least once (the ECS cluster/service and ECR repo must exist —
see `infra/terraform/envs/<env>`), and that the caller's AWS credentials
have `ecs:UpdateService`, `ecs:DescribeServices`, `ecr:DescribeImages`, and
`ecr:BatchDeleteImage` on the target resources.
