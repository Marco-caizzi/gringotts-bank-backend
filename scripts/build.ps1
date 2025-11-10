param(
  [string]$GOARCH = "amd64"
)

$ErrorActionPreference = "Stop"

Write-Host "Building AWS Lambda bootstrap (GOOS=linux GOARCH=$GOARCH)"
$env:GOOS = "linux"
$env:GOARCH = $GOARCH
$env:CGO_ENABLED = "0"

go version

go build -tags "lambda.norpc" -ldflags "-s -w" -o bootstrap ./lambda/GetHealthcheckAPI/cmd

if (!(Test-Path -Path dist)) {
  New-Item -ItemType Directory -Path dist | Out-Null
}

if (Test-Path -Path dist/health.zip) {
  Remove-Item dist/health.zip -Force
}

Compress-Archive -Path bootstrap -DestinationPath dist/health.zip -Force

# Clean local bootstrap binary (kept in dist/health.zip)
if (Test-Path -Path ./bootstrap) {
  Remove-Item ./bootstrap -Force
}

Write-Host "Package created at dist/health.zip"
