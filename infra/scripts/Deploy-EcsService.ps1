<#
.SYNOPSIS
    Forces a fresh ECS Fargate deployment for one service in this repo's
    cluster, waits for steady state, then prunes old untagged ECR images.

.DESCRIPTION
    PowerShell / AWS Tools for PowerShell (AWS.Tools) parity for
    infra/scripts/deploy-ecs-service.sh - same operation, same cluster/
    service/repo naming convention as infra/terraform/modules/compute/ecs.tf
    and ecr.tf. Kept as a working side-by-side comparison of the Bash+AWS CLI
    and PowerShell+AWS.Tools approaches to the same task.

    Requires the AWS.Tools.ECS and AWS.Tools.ECR modules (the modular
    AWS.Tools.* packages, not the monolithic AWSPowerShell/AWSPowerShell.NetCore):
        Install-Module -Name AWS.Tools.Installer -Scope CurrentUser
        Install-AWSToolsModule AWS.Tools.ECS, AWS.Tools.ECR -CleanUp

.PARAMETER Environment
    dev | stage | prod

.PARAMETER Service
    Service key from var.services in infra/terraform/envs/<env>/main.tf,
    e.g. "app" or "app5-fileservice".

.PARAMETER KeepCount
    Number of most-recent untagged images to retain (default 5).

.EXAMPLE
    ./Deploy-EcsService.ps1 -Environment dev -Service app
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Service,
    [int]$KeepCount = 5,
    [string]$Project = "global-multi-tenant-saas-platform",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Import-Module AWS.Tools.ECS -ErrorAction Stop
Import-Module AWS.Tools.ECR -ErrorAction Stop

$Cluster    = "$Project-$Environment-cluster"
$EcsService = "$Project-$Environment-$Service-service"
$EcrRepo    = "$Project-$Environment-$Service"

Write-Host "==> Forcing new deployment: cluster=$Cluster service=$EcsService"
$updated = Update-ECSService -Cluster $Cluster -Service $EcsService -ForceNewDeployment $true -Region $Region
[PSCustomObject]@{
    Status  = $updated.Status
    Desired = $updated.DesiredCount
    Running = $updated.RunningCount
} | Format-Table | Out-String | Write-Host

Write-Host "==> Waiting for service to reach steady state..."
# AWS.Tools has no bundled "wait until stable" cmdlet (unlike `aws ecs wait
# services-stable` in the CLI), so this polls DescribeServices the same way
# that CLI waiter does under the hood.
$timeoutSeconds = 600
$pollSeconds    = 15
$elapsed        = 0

while ($true) {
    $svc = (Get-ECSService -Cluster $Cluster -Service $EcsService -Region $Region)[0]
    $primaryDeployment = $svc.Deployments | Where-Object { $_.Status -eq "PRIMARY" } | Select-Object -First 1
    $rolloutState = if ($primaryDeployment) { $primaryDeployment.RolloutState } else { "UNKNOWN" }
    $stable = ($svc.RunningCount -eq $svc.DesiredCount) -and ($rolloutState -eq "COMPLETED")

    Write-Host "  [+${elapsed}s] running=$($svc.RunningCount)/$($svc.DesiredCount) rollout=$rolloutState"

    if ($stable) {
        Write-Host "==> Deployment stable."
        break
    }
    if ($elapsed -ge $timeoutSeconds) {
        throw "Timed out after ${timeoutSeconds}s waiting for $EcsService to stabilize."
    }
    Start-Sleep -Seconds $pollSeconds
    $elapsed += $pollSeconds
}

Write-Host "==> Pruning untagged images in $EcrRepo older than the most recent $KeepCount..."
$untaggedImages = Get-ECRImageMetadata -RepositoryName $EcrRepo -Filter_TagStatus UNTAGGED -Region $Region |
    Sort-Object ImagePushedAt

$deleteCount = $untaggedImages.Count - $KeepCount
if ($deleteCount -le 0) {
    Write-Host "No untagged images to prune (found $($untaggedImages.Count), keeping $KeepCount)."
    return
}

$toDelete = $untaggedImages | Select-Object -First $deleteCount
$imageIds = $toDelete | ForEach-Object { "imageDigest=$($_.ImageDigest)" }

Remove-ECRImageBatch -RepositoryName $EcrRepo -ImageId $imageIds -Region $Region -Force | Out-Null
Write-Host "==> Deleted $($toDelete.Count) untagged image(s)."
