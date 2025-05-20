#!/bin/bash

# Script to refresh app secrets from a secure source
# This is used during development and CI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔐 Refreshing MCATPrep secrets..."

# Check for required tools
if ! [ -x "$(command -v jq)" ]; then
  echo -e "${RED}Error: jq is not installed.${NC}" >&2
  echo "Please install jq using: brew install jq"
  exit 1
fi

# Path to your secrets file - could be fetched from a secure store in CI
SECRETS_FILE="./.secrets.json"

if [ ! -f "$SECRETS_FILE" ]; then
  echo -e "${RED}Error: Secrets file not found at $SECRETS_FILE${NC}"
  echo "Please make sure you have configured your secrets file."
  exit 1
fi

# Extract secrets
SUPABASE_URL=$(jq -r '.SUPABASE_URL' $SECRETS_FILE)
SUPABASE_KEY=$(jq -r '.SUPABASE_KEY' $SECRETS_FILE)
TORCH_SERVE_URL=$(jq -r '.TORCH_SERVE_URL' $SECRETS_FILE)
API_KEY=$(jq -r '.API_KEY' $SECRETS_FILE)

# Update Config.xcconfig file with secrets
CONFIG_FILE="./MCATPrep/App/SupportingFiles/Config.xcconfig"

echo "// Generated file - Do not edit manually" > $CONFIG_FILE
echo "// Last updated: $(date)" >> $CONFIG_FILE
echo "" >> $CONFIG_FILE
echo "SUPABASE_URL = $SUPABASE_URL" >> $CONFIG_FILE
echo "SUPABASE_KEY = $SUPABASE_KEY" >> $CONFIG_FILE
echo "TORCH_SERVE_URL = $TORCH_SERVE_URL" >> $CONFIG_FILE
echo "API_KEY = $API_KEY" >> $CONFIG_FILE

# Make script executable if necessary
chmod +x "$CONFIG_FILE"

echo -e "${GREEN}✅ Secrets refreshed successfully!${NC}" 