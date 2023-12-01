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

# Function to deploy Azure Resource Group
deploy_resource_group() {
    az group create --name "$resourceGroupName" --location "$location"
}

# Function to deploy Azure App Service Plan
deploy_app_service_plan() {
    az appservice plan create --name "$appServicePlan" --resource-group "$resourceGroupName" --sku S1 --location "$location"
}

# Function to deploy Azure Web App
deploy_web_app() {
    az webapp create --name "$appName" --plan "$appServicePlan" --resource-group "$resourceGroupName"
}

# Function to configure App Settings
configure_app_settings() {
    az webapp config appsettings set --name "$appName" --resource-group "$resourceGroupName" --settings \
        Key1=Value1 \
        Key2=Value2
}

# Function to deploy Azure SQL Database
deploy_sql_database() {
    az sql server create --resource-group "$resourceGroupName" --name "$databaseServerName" --location "$location" --admin-user "$databaseUsername" --admin-password $(read_secret "Enter the SQL Server admin password")

    az sql db create --resource-group "$resourceGroupName" --server "$databaseServerName" --name "$databaseName" --service-objective S0
}

# Function to configure Database Connection String
configure_db_connection_string() {
    az webapp config connection-string set --name "$appName" --resource-group "$resourceGroupName" --settings \
        "$connectionStringName"="Server=$databaseServerName;Database=$databaseName;User Id=$databaseUsername;Password=$databasePassword;"
}

# Function to deploy Git Repository
deploy_git_repo() {
    az webapp deployment source config --name "$appName" --resource-group "$resourceGroupName" --repo-url "$gitRepoUrl" --branch "$gitBranch" --manual-integration
}

# Function to trigger deployment
trigger_deployment() {
    az webapp deployment source sync --name "$appName" --resource-group "$resourceGroupName"
}

# Trap errors
trap 'handle_error' ERR

# Main Deployment Steps

# Step 1: Login to Azure
az login

# Step 2: Set the subscription
az account set --subscription "YourSubscriptionID"

# Step 3: Deploy Azure Resource Group
deploy_resource_group

# Step 4: Deploy Azure App Service Plan
deploy_app_service_plan

# Step 5: Deploy Azure Web App
deploy_web_app

# Step 6: Configure App Settings
configure_app_settings

# Step 7: Deploy Azure SQL Database
deploy_sql_database

# Step 8: Configure Database Connection String
configure_db_connection_string

# Step 9: Deploy Git Repository
deploy_git_repo

# Step 10: Trigger Deployment
trigger_deployment

# Output Deployment URL
echo "Application deployed successfully. Access your app at: https://$appName.azurewebsites.net"
