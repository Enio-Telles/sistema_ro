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
    [switch]$ForceLocalDeletion = $false,
    [string]$Remote = 'origin',
    [string]$MainBranch = 'main',
    [string]$CsvRelativePath = '..\\reports\\branches_status.csv'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csvPath = Join-Path $scriptDir $CsvRelativePath
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV not found: $csvPath"
    exit 1
}

Write-Host "Fetching remote refs (git fetch --all --prune)..." -ForegroundColor Cyan
& git fetch --all --prune 2>$null
if ($LASTEXITCODE -ne 0) { Write-Warning "git fetch returned non-zero exit code. Continuing but merge-base checks may be stale." }

$rows = Import-Csv $csvPath
$commands = @()

function Normalize-Actions($actionsField) {
    if (-not $actionsField) { return @() }
    return ($actionsField -split '[;,]' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne '' })
}

foreach ($r in $rows) {
    $branch = ($r.branch -as [string]).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { continue }
    if ($branch -eq $MainBranch) {
        Write-Host "Skipping protected branch: $branch" -ForegroundColor Yellow
        continue
    }

    $actions = Normalize-Actions($r.suggested_action)
    foreach ($action in $actions) {
        switch ($action) {
            'delete_remote' {
                # check remote existence
                $ls = & git ls-remote --heads $Remote $branch 2>$null
                if ($ls) {
                    $commands += @{ type='remote_delete'; cmd="git push $Remote --delete $branch"; branch=$branch }
                } else {
                    Write-Host "Remote branch not found (skipping remote delete): $branch" -ForegroundColor Yellow
                }
            }
            'delete_local' {
                # check local existence
                & git show-ref --verify --quiet refs/heads/$branch
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Local branch not found (skipping local delete): $branch" -ForegroundColor Yellow
                    continue
                }

                # decide if safe to delete: is branch an ancestor of remote/main?
                $remoteMainRef = "$Remote/$MainBranch"
                & git merge-base --is-ancestor $branch $remoteMainRef
                if ($LASTEXITCODE -eq 0) {
                    $commands += @{ type='local_delete'; cmd="git branch -d $branch"; branch=$branch }
                } elseif ($ForceLocalDeletion) {
                    $commands += @{ type='local_delete_force'; cmd="git branch -D $branch"; branch=$branch }
                } else {
                    Write-Host "Local branch $branch is not merged into $remoteMainRef; skipping. Use -ForceLocalDeletion to force-delete." -ForegroundColor Yellow
                }
            }
            default {
                Write-Host "Unrecognized action '$action' for branch $branch" -ForegroundColor DarkYellow
            }
        }
    }
}

if ($commands.Count -eq 0) {
    Write-Host "No commands to run." -ForegroundColor Cyan
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
    try {
        if ($c.type -eq 'remote_delete') {
            Write-Host "Deleting remote branch: $($c.branch)" -ForegroundColor Green
            & git push $Remote --delete $($c.branch)
            if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to delete remote $($c.branch)" }
        } elseif ($c.type -eq 'local_delete') {
            Write-Host "Deleting local branch: $($c.branch)" -ForegroundColor Green
            & git branch -d $($c.branch)
            if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to delete local $($c.branch) with -d" }
        } elseif ($c.type -eq 'local_delete_force') {
            Write-Host "Force-deleting local branch: $($c.branch)" -ForegroundColor Yellow
            & git branch -D $($c.branch)
            if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to force-delete local $($c.branch)" }
        }
    } catch {
        Write-Warning "Exception while executing command: $($_.Exception.Message)"
    }
}

Write-Host "Done." -ForegroundColor Cyan
