#!/bin/bash

# Define variables
resourceGroupName="YourResourceGroup"
appName="YourAppName"
location="YourAzureRegion"
appServicePlan="YourAppServicePlan"
databaseName="YourDatabaseName"
databaseServerName="YourDatabaseServerName"
databaseUsername="YourDatabaseUsername"
connectionStringName="YourDatabaseConnectionStringName"
gitRepoUrl="YourGitRepoURL"
gitBranch="YourGitBranch"

# Function to prompt for sensitive information
read_secret() {
    local prompt="$1"
    local password
    prompt="${prompt} (will not be echoed): "
    prompt=$(printf "%s" "$prompt" 1>&2)
    IFS= read -rs password
    echo "$password"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    echo "Error occurred with exit code $exit_code"
    exit $exit_code
}

# Trap errors
trap 'handle_error' ERR

# Step 1: Login to Azure
az login

# Step 2: Set the subscription
az account set --subscription "YourSubscriptionID"

# Step 3: Create or update Azure Resource Group
az group create --name "$resourceGroupName" --location "$location"

# Step 4: Deploy the App Service Plan
az appservice plan create --name "$appServicePlan" --resource-group "$resourceGroupName" --sku S1 --location "$location"

# Step 5: Deploy the App Service
az webapp create --name "$appName" --plan "$appServicePlan" --resource-group "$resourceGroupName"

# Step 6: Configure the App Settings (assuming your app needs some environment variables)
az webapp config appsettings set --name "$appName" --resource-group "$resourceGroupName" --settings \
  Key1=Value1 \
  Key2=Value2

# Step 7: Deploy the Database
az sql server create --resource-group "$resourceGroupName" --name "$databaseServerName" --location "$location" --admin-user "$databaseUsername" --admin-password $(read_secret "Enter the SQL Server admin password")

az sql db create --resource-group "$resourceGroupName" --server "$databaseServerName" --name "$databaseName" --service-objective S0

# Step 8: Configure Database Connection String in App Settings
az webapp config connection-string set --name "$appName" --resource-group "$resourceGroupName" --settings \
  "$connectionStringName"="Server=$databaseServerName;Database=$databaseName;User Id=$databaseUsername;Password=$databasePassword;"

# Step 9: Deploy your application code (assuming your code is in a Git repository)
az webapp deployment source config --name "$appName" --resource-group "$resourceGroupName" --repo-url "$gitRepoUrl" --branch "$gitBranch" --manual-integration

# Step 10: Trigger a deployment
az webapp deployment source sync --name "$appName" --resource-group "$resourceGroupName"

# Optional: You may want to add additional steps for other resources like storage, cache, etc.

# Output Deployment URL
echo "Application deployed successfully. Access your app at: https://$appName.azurewebsites.net"
