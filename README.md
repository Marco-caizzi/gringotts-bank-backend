# Gringotts Bank Backend – Serverless Foundations

This repository provides the backend serverless foundation intended to satisfy the needs expressed in the companion project “Gringotts Bank” (see https://github.com/PabloPonte/gringotts-bank). It establishes a repeatable pattern and shared infrastructure to run multiple AWS Lambdas behind API Gateway, with a local development workflow powered by LocalStack and Terraform.

- Runtime (pattern): Go 1.22 custom runtime (binary named `bootstrap` per Lambda)
- Local infrastructure applied: Terraform targeting LocalStack (API Gateway REST v1, Lambda, IAM, CloudWatch Logs, S3, DynamoDB services enabled in docker-compose)
- Common configuration across lambdas: `ENV`, `LOG_LEVEL`

## Architecture & layering pattern
Each lambda should follow the same small layered separation for clarity and testability:
- `cmd/` – composition root (main.go) wiring config + processor + handler and adapting it to Lambda runtime.
- `config/` – reads and validates the lambda-specific required env vars. Shared conventions: `ENV`, `LOG_LEVEL`.
- `processor/` – business logic (pure domain / application layer). Expose a small interface consumed by handler.
- `handler/` – HTTP adapter implementing `http.Handler` (`ServeHTTP`) and isolating protocol concerns from business logic.

This pattern keeps methods isolated: prefer 1 HTTP method per lambda (separate lambdas per verb when semantics differ), avoiding mixed verb routing inside one handler. API Gateway (REST v1) integrates as `AWS_PROXY` with each Lambda. REST v1 is used locally to maximize compatibility with the open-source LocalStack image.

## Requirements
- Docker Desktop (or compatible)
- Go 1.22+
- Terraform 1.5+
- LocalStack image (pulled automatically by Docker Compose)
- Windows PowerShell (or cmd) / Bash (Git Bash/WSL/Linux/macOS)

## Quickstart (Bash one-shot)
If you have Bash available (Git Bash/WSL/Linux/macOS):

```bash
./scripts/local-e2e.sh up
```
This will:
- Start LocalStack via docker compose
- Build the serverless artifacts defined by the scripts
- Apply Terraform to LocalStack (API Gateway REST v1 + Lambda, IAM, Logs)

Stop containers:
```bash
./scripts/local-e2e.sh down
```

## Windows: bring everything up (infrastructure applied)
Using PowerShell from repo root:

```powershell
# Start LocalStack and supporting services
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-up.ps1

# Build artifacts and apply Terraform against LocalStack
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1
```
Notes:
- Include the `.ps1` extension when running PowerShell scripts.
- Terraform writes useful outputs (e.g., base API endpoint) under `dist/` when configured to do so.

## Environment variables (shared convention)
- `ENV` (required): execution environment (local, dev, prod, etc.).
- `LOG_LEVEL` (optional): `debug|info|warn|error` default `info`. "warning" normalizes to `warn`.
Additional lambda-specific variables can be added per lambda in its `config` package.

## Build and package (manual)
Bash/Make (optional):
```bash
make clean && make package
```
PowerShell:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
```
These commands compile the `bootstrap` binary for linux/amd64 and produce a zip in `dist/` according to the scripts.

## Terraform (LocalStack)
Terraform code under `infra/terraform/localstack` configures the AWS provider to point at LocalStack’s edge endpoint (`http://localhost:4566`) and intentionally skips real AWS credentials (uses test values and disables account checks). The applied infrastructure includes:
- IAM role and basic execution policy for Lambda
- CloudWatch Log Group per lambda
- Lambda function(s) with `provided.al2023` runtime and `bootstrap` handler
- API Gateway REST (v1) with resources/methods and `AWS_PROXY` integration
- Deployment and stage configuration

Apply:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1
```
Destroy:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-destroy.ps1
```

## OpenAPI documentation
- Location: `doc/openapi/apis.yaml` (single source of truth for public HTTP contracts).
- Conventions: document each resource and method; keep one method per lambda by design (separate lambdas per verb when needed).
- Validation: keep the spec valid OpenAPI 3.x; PRs should update the spec alongside code changes.
- Serve locally with Swagger UI:
  - Bash/Linux/macOS:
    ```bash
    docker run --rm -p 8080:8080 \
      -e SWAGGER_JSON=/spec/apis.yaml \
      -v "$(pwd)/doc/openapi:/spec" \
      swaggerapi/swagger-ui
    ```
  - Windows PowerShell (ajusta la ruta si fuera necesario):
    ```powershell
    docker run --rm -p 8080:8080 `
      -e SWAGGER_JSON=/spec/apis.yaml `
      -v ${PWD}/doc/openapi:/spec `
      swaggerapi/swagger-ui
    ```
  - Then open http://localhost:8080 in your browser.

Optionally, you can add an OpenAPI linter/validator in CI (e.g., Redocly or `openapi-cli`) if you want automated checks.

## CI/CD (proposal)
Goal: fast feedback (lint/test/build), reproducible packaging, infra validation against LocalStack, and artifact publication. A minimal GitHub Actions pipeline could:

- Trigger: on PRs to main and on push to main.
- Jobs:
  1) Go Lint & Tests:
    - setup-go, cache modules, `go mod tidy -compat=<go.mod version>`, `go test -cover ./...`.
    - upload coverage as artifact (optional).
  2) Package lambdas:
    - build linux/amd64 `bootstrap` per lambda and zip under `dist/`.
    - upload zips como artifacts del workflow.
  3) Terraform validate/plan (LocalStack):
    - start LocalStack as service in Actions.
    - run `terraform fmt -check`, `terraform init`, `terraform validate`, `terraform plan` in `infra/terraform/localstack`.
    - optional smoke: derive endpoint de `terraform output` e invocar con `curl` (siempre contra LocalStack, no AWS real).

Notes:
- El job `package` muestra un patrón para una lambda; para múltiples, iterar sobre `lambda/*/cmd` o crear scripts que empaqueten todas.
- Para despliegue a AWS real, crear un workflow separado con credenciales seguras (OIDC o secretos), y usar `terraform plan/apply` contra AWS, no LocalStack.

## Tests and coverage
Run all tests with coverage:
```powershell
go test -cover ./...
```
Or Bash:
```bash
go test -cover ./...
```
Optional coverage detail:
```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

## Relation to the Gringotts Bank project
This backend lays the groundwork and infrastructure to implement the capabilities described in https://github.com/PabloPonte/gringotts-bank. As business features evolve there, corresponding lambdas and API resources can be added here adhering to the same layering and infrastructure pattern.
