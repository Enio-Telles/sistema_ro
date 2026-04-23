$token = (Get-Content .env | ForEach-Object { if ($_ -match '^\s*GITHUB_TOKEN\s*=\s*(.+)\s*$') { $matches[1].Trim(); break } })
if (-not $token) { Write-Output 'GITHUB_TOKEN not found'; exit 1 }

$runIds = @(24852110059, 24852111304)
foreach ($runid in $runIds) {
    $outDir = ".\ci_logs\run-$runid"
    $outZip = ".\ci_logs\run-$runid.zip"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $uri = "https://api.github.com/repos/Enio-Telles/sistema_ro/actions/runs/$runid/logs"
    Write-Output "Requesting run $runid logs..."
    try {
        $resp = Invoke-WebRequest -Uri $uri -Headers @{ Authorization = "token $token"; 'User-Agent' = 'sistema_ro-agent' } -Method Get -MaximumRedirection 0 -ErrorAction Stop
        Write-Output ("Status: {0}" -f $resp.StatusCode)
        if ($resp.Headers.Location) {
            $loc = $resp.Headers.Location
            Write-Output ("Downloading from: {0}" -f $loc)
            Invoke-WebRequest -Uri $loc -OutFile $outZip -UseBasicParsing -ErrorAction Stop
            $size = (Get-Item $outZip).Length
            Write-Output ("Downloaded {0} bytes" -f $size)
            if ($size -gt 0) {
                Expand-Archive -Path $outZip -DestinationPath $outDir -Force
                Write-Output ("Extracted to {0}" -f $outDir)
            } else { Write-Output ("Zip empty for run {0}" -f $runid) }
        } else {
            Write-Output ("No Location header for run {0}. Status: {1}" -f $runid, $resp.StatusCode)
        }
    } catch {
        Write-Output ("Error for run {0}: {1}" -f $runid, $_.Exception.Message)
    }
}
Write-Output "Listing ci_logs:"
Get-ChildItem -Recurse .\ci_logs | Select FullName, Length | Format-Table | Out-String | Write-Output
