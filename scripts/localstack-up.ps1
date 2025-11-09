param(
  [switch]$Rebuild
)
$ErrorActionPreference = "Stop"
if ($Rebuild) {
  docker compose down -v
}
Write-Host "Starting LocalStack + Postgres..."
docker compose up -d
Write-Host "Waiting for LocalStack on :4566..."
$max=60
for ($i=0; $i -lt $max; $i++) {
  try {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri http://localhost:4566/health -TimeoutSec 2
    if ($resp.StatusCode -eq 200) { break }
  } catch {}
  Start-Sleep -Seconds 1
}
Write-Host "LocalStack ready."

