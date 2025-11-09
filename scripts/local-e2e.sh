#!/usr/bin/env bash
set -euo pipefail

# local-e2e.sh
# Bring up LocalStack, build & deploy the lambda with Terraform, and hit the /health endpoint.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform/localstack"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/health.zip"
BOOTSTRAP_PATH="$ROOT_DIR/bootstrap"

# Select docker compose command
if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE=(docker compose)
else
  DOCKER_COMPOSE=(docker-compose)
fi

log() { echo -e "[local-e2e] $*"; }
err() { echo -e "[local-e2e][ERROR] $*" >&2; }

wait_for_localstack() {
  local url=${1:-"http://localhost:4566"}
  local max_retries=${2:-60}
  local i=0
  log "Waiting for LocalStack at ${url} ..."
  until curl -sS --fail "${url}/_localstack/health" >/dev/null 2>&1; do
    i=$((i+1))
    if [[ $i -ge $max_retries ]]; then
      err "LocalStack did not become ready after $max_retries attempts"
      exit 1
    fi
    sleep 2
  done
  log "LocalStack is up."
}

build_lambda() {
  log "Building AWS Lambda bootstrap (GOOS=linux GOARCH=amd64)"
  pushd "$ROOT_DIR" >/dev/null
  GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags "lambda.norpc" -ldflags "-s -w" -o "$BOOTSTRAP_PATH" ./lambda/GetHealthcheckAPI/cmd
  mkdir -p "$DIST_DIR"
  rm -f "$ZIP_PATH"
  if command -v zip >/dev/null 2>&1; then
    (cd "$ROOT_DIR" && zip -j "$ZIP_PATH" "$BOOTSTRAP_PATH")
  else
    err "zip command not found. Please install 'zip' (InfoZip) to continue."
    exit 1
  fi
  log "Package created at $ZIP_PATH"
  popd >/dev/null
}

deploy_terraform() {
  log "Applying Terraform to LocalStack..."
  pushd "$TF_DIR" >/dev/null
  terraform init -input=false
  terraform apply -auto-approve
  API_ENDPOINT=$(terraform output -raw api_endpoint)
  echo "$API_ENDPOINT" > "$DIST_DIR/api_endpoint.txt"
  log "API endpoint: $API_ENDPOINT"
  popd >/dev/null
}

invoke_health() {
  local endpoint
  if [[ -f "$DIST_DIR/api_endpoint.txt" ]]; then
    endpoint="$(cat "$DIST_DIR/api_endpoint.txt")"
  else
    err "api_endpoint.txt not found; was Terraform applied?"
    exit 1
  fi
  log "Invoking GET ${endpoint}/health ..."
  # -k to accept LocalStack self-signed certs when using https localhost.localstack.cloud
  curl -sS -k -i "${endpoint}/health" | sed -e 's/^/[curl] /'
}

usage() {
  cat <<EOF
Usage: $0 [up|down|deploy|invoke]
  up      - Start LocalStack, build package, apply Terraform and invoke /health (default)
  down    - Stop LocalStack containers (docker compose down)
  deploy  - Build package and apply Terraform only
  invoke  - Invoke /health using stored api_endpoint
EOF
}

cmd=${1:-up}
case "$cmd" in
  up)
    log "Starting LocalStack via Docker Compose..."
    "${DOCKER_COMPOSE[@]}" up -d localstack
    wait_for_localstack "http://localhost:4566"
    build_lambda
    deploy_terraform
    invoke_health
    ;;
  down)
    log "Stopping LocalStack containers..."
    "${DOCKER_COMPOSE[@]}" down
    ;;
  deploy)
    build_lambda
    deploy_terraform
    ;;
  invoke)
    invoke_health
    ;;
  *)
    usage
    exit 1
    ;;

esac

