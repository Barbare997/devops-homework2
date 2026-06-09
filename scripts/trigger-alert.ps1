# Sends sustained 500 responses so the error rate stays above 5/min long enough to fire the alert.

param(
    [int]$Rounds = 12,
    [int]$PerRound = 8,
    [int]$PauseSec = 5
)

$baseUrl = "http://localhost:3000/api/error"
Write-Host "Hitting $baseUrl ($PerRound requests x $Rounds rounds)..."

for ($round = 1; $round -le $Rounds; $round++) {
    for ($i = 1; $i -le $PerRound; $i++) {
        try {
            Invoke-WebRequest -Uri $baseUrl -UseBasicParsing | Out-Null
        } catch {
            # 500s throw in PowerShell — expected
        }
    }
    Write-Host "Round $round/$Rounds done"
    Start-Sleep -Seconds $PauseSec
}

Write-Host ""
Write-Host "Done. Refresh http://localhost:9090/alerts every 15-20s."
Write-Host "Expect Pending first, then FIRING after about a minute."
