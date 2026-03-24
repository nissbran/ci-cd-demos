# Deploying the infrastructure

The infrastructure can be deployed using the Azure CLI. First, create a resource group for the infrastructure:

```bash
az group create --name rg-cicd-demo-test --location swedencentral
```

Then, deploy the Bicep template:

```bash
az deployment group create --resource-group rg-cicd-demo-test --template-file main.bicep --parameters baseName=cicd-demo environment=test
```

Create a service principal for GitHub Actions with contributor role at the resource group level (replace the subscription ID with your own), and make sure to copy the output JSON as it will be needed for GitHub Actions secrets:

```bash
$ENV:AZURE_SUBSCRIPTION_ID = '--' # replace with your subscription ID
az ad sp create-for-rbac --name "GitHub-Actions-CICD-Demo-Test" --role contributor --scopes /subscriptions/$ENV:AZURE_SUBSCRIPTION_ID/resourceGroups/rg-cicd-demo-test
```

Add fedret identity credentials for GitHub Actions to access the infrastructure (replace the placeholders with your own values):

```bash
$ENV:AZURE_APP_ID = '--' # replace with the appId from the previous command output
az ad app federated-credential create --id $ENV:AZURE_APP_ID --parameters credential.json
```

Where `credential.json` contains the following (replace the placeholders with your own values):
```json
{
    "name": "DeploymentCredentialTest",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:nissbran/ci-cd-demos:environment:test",
    "description": "Federated identity credential for GitHub Actions to access Azure resources for the test environment",
    "audiences": [
        "api://AzureADTokenExchange"
    ]
}
```

Add it to the test environment in GitHub repository secrets as 
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

