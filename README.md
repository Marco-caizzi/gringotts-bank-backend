# Gringotts Bank Backend – Serverless Foundations

Este repositorio establece la base serverless e infraestructura para soportar múltiples lambdas de forma consistente y reproducible, alineado con las necesidades del proyecto “Gringotts Bank” (https://github.com/PabloPonte/gringotts-bank). Se prioriza un flujo local robusto con LocalStack + Terraform y un patrón de capas simple en Go.

- Runtime base: Go 1.25 con custom runtime (binario `bootstrap` por lambda)
- Infraestructura local aplicada: Terraform apuntando a LocalStack (API Gateway REST v1, Lambda, IAM, CloudWatch Logs, S3, DynamoDB habilitados en docker-compose)
- Configuración común por lambda: `ENV`, `LOG_LEVEL`

## Patrón de arquitectura y capas
Cada lambda sigue una separación mínima para claridad y testabilidad:
- `cmd/` – composition root: instancia configuración + processor + handler y adapta a runtime Lambda.
- `config/` – lectura/validación de variables de entorno (convenciones: `ENV`, `LOG_LEVEL`).
- `processor/` – lógica de negocio (interfaces del dominio). La capa superior depende de una interfaz, no de la implementación.
- `handler/` – adaptador HTTP implementando `http.Handler` (`ServeHTTP`), sin mezclar verbos cuando la semántica difiere.

API Gateway (REST v1) integra por `AWS_PROXY` con cada lambda, y se prefiere separar endpoints/verbos en lambdas distintas.

## Requisitos
- Docker Desktop (última versión estable)
- Go 1.25.x
- Terraform 1.6.x (>= 1.5 funciona; en CI se usa 1.6.6)
- LocalStack (se levanta vía `docker-compose.yml`)
- PowerShell (Windows) o Bash (Linux/macOS/WSL)
- Opcional para scripts Bash: `zip` y `curl` en el PATH
- Opcional para aplicar en AWS manualmente: Terragrunt

## Quickstart local (Bash)
```bash
./scripts/local-e2e.sh up
```
Detener:
```bash
./scripts/local-e2e.sh down
```

## Quickstart Windows (PowerShell)
```powershell
# Levantar LocalStack y Postgres
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-up.ps1

# Build + Terraform (LocalStack)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1

# Invocar endpoint expuesto por Terraform
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\localstack-invoke.ps1
```

## Terraform – LocalStack
El stack bajo `infra/terraform/localstack` configura el provider AWS hacia `http://localhost:4566`, omite validaciones de cuenta y usa credenciales dummy. Recursos aplicados localmente:
- Role y policies básicas de ejecución para Lambda
- Log groups en CloudWatch
- Lambdas `provided.al2023` con handler `bootstrap`
- API Gateway REST v1 con integración `AWS_PROXY` y stage

Aplicar/Destruir:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-apply.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tf-local-destroy.ps1
```

## OpenAPI
- Ubicación: `doc/openapi/apis.yaml` como fuente única de contratos HTTP públicos.
- Criterios: documentar recursos/métodos; mantener un método por lambda cuando aplica.
- Visualización local (Swagger UI):
  - Bash/Linux/macOS:
    ```bash
    docker run --rm -p 8080:8080 \
      -e SWAGGER_JSON=/spec/apis.yaml \
      -v "$(pwd)/doc/openapi:/spec" \
      swaggerapi/swagger-ui
    ```
  - Windows PowerShell:
    ```powershell
    docker run --rm -p 8080:8080 `
      -e SWAGGER_JSON=/spec/apis.yaml `
      -v ${PWD}/doc/openapi:/spec `
      swaggerapi/swagger-ui
    ```

## CI/CD (propuesta)
Pipeline mínimo en GitHub Actions para calidad, empaquetado y validación infra local:
- Disparadores: PRs a main y pushes a main.
- Jobs:
  1) Lint + Tests Go
     - setup-go + cache, `go mod tidy`, `go test -cover ./...`.
  2) Empaquetado
     - build linux/amd64 del binario `bootstrap` por lambda y zip en `dist/`.
     - publicar zips como artifacts.
  3) Terraform validate/plan (LocalStack)
     - levantar LocalStack como servicio del workflow.
     - `terraform fmt -check`, `terraform init`, `terraform validate`, `terraform plan` en `infra/terraform/localstack`.
     - (opcional) smoke test: leer `terraform output` e invocar `/health` con `curl`.

Para entornos AWS reales (dev/prod): usar Terragrunt en `infra/terragrunt/live/*`, inyectar VPC/Subnets/SG, y habilitar módulos como RDS desde un root `infra/terraform/app` (plan/apply con approvals). Credenciales vía OIDC o secretos cifrados, con protección de ramas.

## Perspectiva de crecimiento
Este repositorio está diseñado para escalar a múltiples lambdas y recursos de infraestructura, reutilizando el mismo patrón de capas y módulos Terraform. Las capacidades descritas en “Gringotts Bank” se implementarán aquí como endpoints y servicios, manteniendo consistencia entre ambientes locales y cloud.
