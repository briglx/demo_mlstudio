# Demo Azure ML Studio with VS Code

This project demonstrates how to connect VS Code to Azure ML Studio and run a simple experiment.

## Architecture Diagram


## Create System Identities

The solution uses several system identities.

| System Identities        | Authentication                                             | Authorization                                                                                                                     | Purpose                                                                             |
| ------------------------ | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `env.AZURE_CLIENT_ID` | [EnvironmentCredential](https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/identity/azure-identity/TROUBLESHOOTING.md#troubleshoot-environmentcredential-authentication-issues)       | <ul><li>TBD</li></ul>  |  Manage the ml workspace resources and jobs.  |

```bash
# Configure the environment variables. Copy `example.env` to `.env` and update the values
cp example.env .env

# load .env vars (optional)
[ ! -f .env ] || eval "export $(grep -v '^#' .env | xargs)"
# or this version allows variable substitution and quoted long values
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Login to cloud cli. Only required once per install.
az login --tenant $AZURE_TENANT_ID

# Create Azure ML App client identity
# ./scripts/create_app_sp.sh --name "$APP_NAME"

```

## Provision Data

```bash
# Download the example data.
mkdir ./data
cd ./data
wget https://azuremlexamples.blob.core.windows.net/datasets/credit_card/default_of_credit_card_clients.csv
```
