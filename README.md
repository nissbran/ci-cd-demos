# ci-cd-demos

Demos for CI/CD with GitHub Actions and Azure — covering Azure Functions (C# .NET 8) and Logic Apps Standard.

## What's included

| Component | Path |
|---|---|
| Azure Functions demo | `src/functions/DemoFunctionApp/` |
| Logic App Standard demo | `src/logic-apps/DemoLogicApp/` |
| Bicep IaC | `infra/` |
| CI/CD pipeline | `.github/workflows/ci-cd.yml` |
| IaC workflow | `.github/workflows/infra-deploy.yml` |

## Pipeline overview

```
CI (parallel build)
  ├── build-functions
  └── build-logic-app
        ↓
deploy-test  (no approval)
        ↓
deploy-staging  ← approval required
        ↓
deploy-prod     ← approval required
```

Within each deploy stage, Functions and Logic App are deployed **in parallel**.

## Setup

### 1. Create GitHub Environments

In **Settings → Environments**, create three environments and configure required reviewers on `staging` and `prod`:

| Environment | Protection |
|---|---|
| `test` | none |
| `staging` | required reviewers |
| `prod` | required reviewers |

### 2. Configure OIDC credentials per environment

For each environment, add these secrets:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

Set up federated credentials on the app registration for each environment:
- Entity type: **Environment**
- Environment name: `test` / `staging` / `prod`

### 3. Deploy infrastructure first

Run the **Deploy Infrastructure (Bicep)** workflow (`infra-deploy.yml`) via `workflow_dispatch` for each environment before running the CI/CD pipeline. Provide the target resource group name.

Resource groups must already exist (naming convention: `rg-cicd-demo-<environment>`).

### 4. (Optional) Override app names

Set repository variables if your resource names differ from the defaults:
- `FUNCTION_APP_NAME_TEST`, `FUNCTION_APP_NAME_STAGING`, `FUNCTION_APP_NAME_PROD`
- `LOGIC_APP_NAME_TEST`, `LOGIC_APP_NAME_STAGING`, `LOGIC_APP_NAME_PROD`

