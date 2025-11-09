# Scripts guide

This folder contains helper scripts to support local development with LocalStack and Terraform, as well as building and invoking serverless artifacts.

Prerequisites (depending on script):
- Docker Desktop
- Terraform 1.5+
- Go toolchain (for build scripts)
- PowerShell (Windows) or Bash (Git Bash/WSL/Linux/macOS)
- curl and zip (for the Bash end-to-end script)

Note about Windows usage:
- From cmd.exe, prefer invoking PowerShell scripts explicitly:
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\<script>.ps1
  ```

---

## build.ps1
Builds the Go Lambda binary (`bootstrap`) for linux/amd64 and packages it into `dist/health.zip`.

- What it does:
  - Sets `GOOS=linux`, `GOARCH` (default `amd64`), `CGO_ENABLED=0`.
  - Compiles the `bootstrap` binary from `./lambda/GetHealthcheckAPI/cmd` with `-tags lambda.norpc`.
  - Creates/overwrites `dist/health.zip` with the `bootstrap` file.
- Parameters:
  - `GOARCH` (optional): defaults to `amd64`. Example: `arm64`.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
  ```
- Notes:
  - The plain `bootstrap` file is ignored by git; only the zip is needed by Terraform.

---

## local-e2e.sh
One-shot Bash workflow to bring up LocalStack, build, deploy via Terraform, and perform a smoke GET request to the API.

- Subcommands:
  - `up` (default): start LocalStack, wait for health, build & package, apply Terraform, invoke endpoint.
  - `down`: docker compose down (stop containers).
  - `deploy`: build & package and `terraform apply` only (assumes LocalStack is already up).
  - `invoke`: read stored API endpoint and call `/health`.
- What it does under the hood:
  - Chooses `docker compose` or `docker-compose` automatically.
  - Waits on `http://localhost:4566/_localstack/health`.
  - Builds `bootstrap` and zips `dist/health.zip`.
  - Runs Terraform from `infra/terraform/localstack`.
  - Stores the base API URL in `dist/api_endpoint.txt` and performs a `curl` to `/health`.
- Usage (Bash):
  ```bash
  ./scripts/local-e2e.sh up
  ./scripts/local-e2e.sh down
  ```
- Requirements:
  - `curl` and `zip` must be available in PATH.

---

## localstack-up.ps1
Starts LocalStack (and Postgres from `docker-compose.yml`) and waits for readiness.

- Behavior:
  - Optional `-Rebuild` flag to run `docker compose down -v` before starting.
  - `docker compose up -d` for all services in the compose file.
  - Polls `http://localhost:4566/health` until HTTP 200.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-up.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-up.ps1 -Rebuild
  ```

---

## localstack-down.ps1
Stops and removes LocalStack (and Postgres) containers and volumes.

- Behavior:
  - Runs `docker compose down -v`.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-down.ps1
  ```

---

## tf-local-apply.ps1
Builds the deployment package and applies the Terraform stack against LocalStack.

- Behavior:
  - Calls `scripts/build.ps1` to produce `dist/health.zip`.
  - Runs `terraform init` and `terraform apply` inside `infra/terraform/localstack`.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1
  ```
- Notes:
  - The Terraform configuration targets LocalStack endpoints and does not require real AWS credentials.

---

## tf-local-destroy.ps1
Destroys the Terraform-managed resources on LocalStack.

- Behavior:
  - Runs `terraform destroy -auto-approve` inside `infra/terraform/localstack`.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-destroy.ps1
  ```

---

## localstack-invoke.ps1
Reads the Terraform output `api_endpoint` and performs a GET request to `/health`.

- Behavior:
  - Executes `terraform output -raw api_endpoint` inside `infra/terraform/localstack`.
  - Appends `/health` and invokes it with `Invoke-WebRequest`.
  - Prints HTTP status and response body.
- Usage (Windows cmd):
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-invoke.ps1
  ```
- Common issues:
  - If `api_endpoint` is empty, run `tf-local-apply.ps1` first to generate outputs.
  - Ensure LocalStack is up (`localstack-up.ps1`).

---

## Typical local flows
- End-to-end on Bash:
  ```bash
  ./scripts/local-e2e.sh up
  # ... work ...
  ./scripts/local-e2e.sh down
  ```
- Windows (cmd) step-by-step:
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-up.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-invoke.ps1
  :: When done
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-destroy.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-down.ps1
  ```

## Troubleshooting notes
- Always include the `.ps1` extension when invoking PowerShell scripts from `cmd.exe`.
- LocalStack v2 API Gateway (apigatewayv2) features may return 501 in OSS; this stack uses REST v1 to maximize compatibility.
- If Terraform reports credential errors, verify the LocalStack provider configuration is being used (endpoints + skip checks).
- If the `dist/health.zip` is stale or missing, rebuild using `scripts/build.ps1`.
- If `local-e2e.sh` fails due to missing `curl` or `zip`, install them or use the Windows PowerShell scripts instead.

