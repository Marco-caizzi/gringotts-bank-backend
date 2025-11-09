$ErrorActionPreference = "Stop"
Write-Host "Stopping LocalStack + Postgres..."
docker compose down -v

