<#
scripts/branch_cleanup.ps1
Helper PowerShell script to preview and (optionally) apply branch cleanup commands.

Usage (dry-run, default):
  powershell -ExecutionPolicy Bypass -File scripts/branch_cleanup.ps1

To execute deletions (requires appropriate repo permissions):
  powershell -ExecutionPolicy Bypass -File scripts/branch_cleanup.ps1 -Apply

Safety: the script will skip `main` and requires interactive confirmation before applying changes.
#>

Param(
    [switch]$Apply = $false,
    [switch]$ForceLocalDeletion = $false
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csvPath = Join-Path $scriptDir '..\reports\branches_status.csv'
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV not found: $csvPath"
    exit 1
}

$rows = Import-Csv $csvPath
$commands = @()

foreach ($r in $rows) {
    $branch = $r.branch.Trim()
    if ($branch -eq 'main' -or $branch -eq 'origin') {
        Write-Host "Skipping protected branch: $branch"
        continue
    }
    $action = $r.suggested_action
    if ($action -match 'delete_remote') {
        $commands += @{ type='remote_delete'; cmd="git push origin --delete $branch"; branch=$branch }
    }
    if ($action -match 'delete_local') {
        $commands += @{ type='local_delete'; cmd="git branch -d $branch"; cmd_force="git branch -D $branch"; branch=$branch }
    }
}

if ($commands.Count -eq 0) {
    Write-Host "No commands to run."
    exit 0
}

Write-Host "Planned commands ($($commands.Count)):" -ForegroundColor Cyan
foreach ($c in $commands) { Write-Host $c.cmd }

if (-not $Apply) {
    Write-Host "`nDry run: nothing was executed. Re-run with -Apply to execute the commands." -ForegroundColor Yellow
    exit 0
}

# Confirm interactive approval
$confirm = Read-Host "You are about to execute $($commands.Count) git commands. Type 'yes' to continue"
if ($confirm -ne 'yes') {
    Write-Host "Aborted by user." -ForegroundColor Yellow
    exit 0
}

foreach ($c in $commands) {
    if ($c.type -eq 'remote_delete') {
        Write-Host "Deleting remote branch: $($c.branch)" -ForegroundColor Green
        & git push origin --delete $($c.branch)
        if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to delete remote $($c.branch)" }
    } elseif ($c.type -eq 'local_delete') {
        Write-Host "Deleting local branch: $($c.branch)" -ForegroundColor Green
        # check if branch is merged into origin/main
        git merge-base --is-ancestor $($c.branch) origin/main
        if ($LASTEXITCODE -eq 0) {
            & git branch -d $($c.branch)
        } elseif ($ForceLocalDeletion) {
            & git branch -D $($c.branch)
        } else {
            Write-Warning "Local branch $($c.branch) is not merged into origin/main; skipping. Use -ForceLocalDeletion to force-delete."
        }
    }
}

Write-Host "Done." -ForegroundColor Cyan
