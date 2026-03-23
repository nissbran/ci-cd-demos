# Copilot Instructions

## Purpose

Demo repository for CI/CD pipelines targeting Azure Functions (C# .NET 8 isolated worker) and Logic Apps Standard (single-tenant) using GitHub Actions and Bicep IaC.

## Repository Structure

```
src/functions/DemoFunctionApp/   # C# .NET 8 isolated worker Function App
src/logic-apps/DemoLogicApp/     # Standard Logic App (workflows under Workflows/<name>/workflow.json)
infra/main.bicep                 # Bicep entry point (env param: test | staging | prod)
infra/modules/                   # function-app.bicep, logic-app.bicep
.github/workflows/               # All GitHub Actions workflows
```

## Pipeline Design

- `ci-cd.yml` — main pipeline: CI builds Functions + Logic App in parallel, then releases through test → staging → prod
- `reusable-deploy-functions.yml` / `reusable-deploy-logic-app.yml` — called per stage via `workflow_call`
- `infra-deploy.yml` — on-demand only (`workflow_dispatch`); deploys Bicep to a selected environment

**Approval gates** are enforced via GitHub Environments (`staging`, `prod` require reviewers). `test` has no gate.

Each deploy stage calls both reusable workflows in parallel (Functions + Logic App deploy simultaneously).

## GitHub Actions Conventions

- Reusable workflows use `workflow_call`; shared deploy logic must not be duplicated in `ci-cd.yml`
- Each reusable workflow declares `environment: ${{ inputs.environment }}` on its job — this is what triggers the GitHub Environment approval gate
- Deployments are only triggered on pushes to `main` (`if: github.ref == 'refs/heads/main'`); PRs only run the CI build jobs
- App names are read from repository variables (`vars.FUNCTION_APP_NAME_TEST`, etc.) with inline defaults as fallback

## Azure Integration

- Auth: OIDC via `azure/login@v2` with `client-id`, `tenant-id`, `subscription-id` — no long-lived credentials
- Secrets required per environment: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- Logic App zip deploy uses: `az logicapp deployment source config-zip`
- Resource group naming convention: `rg-cicd-demo-<environment>`

## Bicep Conventions

- `infra/main.bicep` takes `environment` (allowed: `test`, `staging`, `prod`) and `baseName` params
- Resource names are derived as `${baseName}-<type>-${environment}` (e.g., `cicd-demo-func-test`)
- Storage account names strip hyphens and use `toLower()` to meet Azure naming rules
