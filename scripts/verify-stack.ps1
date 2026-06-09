param(
    [switch]$SkipAlert
)

$ErrorActionPreference = "Stop"

function Test-Endpoint {
    param([string]$Name, [string]$Url, [string]$Pattern = $null)
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing
    if ($Pattern -and ($resp.Content -notmatch $Pattern)) {
        throw "$Name check failed: pattern '$Pattern' not found"
    }
    Write-Host "[ok] $Name"
}

Write-Host "Checking observability stack..."
Test-Endpoint -Name "App health" -Url "http://localhost:3000/health"
Test-Endpoint -Name "App metrics" -Url "http://localhost:3000/metrics" -Pattern "app_requests_total"
Test-Endpoint -Name "Prometheus" -Url "http://localhost:9090/-/ready"
Test-Endpoint -Name "Grafana" -Url "http://localhost:3001/api/health"
Test-Endpoint -Name "Loki" -Url "http://localhost:3100/ready"

if (-not $SkipAlert) {
    Write-Host "Generating sample traffic..."
    Invoke-WebRequest -Uri "http://localhost:3000/api/data" -UseBasicParsing | Out-Null
    Write-Host "[ok] Traffic sent. Run .\scripts\trigger-alert.ps1 to test alerting."
}

Write-Host "All checks passed."
