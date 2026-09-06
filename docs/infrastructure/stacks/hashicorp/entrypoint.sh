#!/bin/bash

# Start Vault in background
vault server -config=/vault-config.hcl &
VAULT_PID=$!

# Wait for Vault to be ready
sleep 10

export VAULT_ADDR="https://keys.bryanwills.dev"
export VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN_ID}"

# Initialize Vault if not already done
vault status > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Initializing Vault..."
    vault operator init -key-shares=1 -key-threshold=1 > /tmp/vault-keys.txt
    export VAULT_UNSEAL_KEY=$(grep 'Unseal Key 1:' /tmp/vault-keys.txt | cut -d: -f2 | tr -d ' ')
    export VAULT_ROOT_TOKEN=$(grep 'Initial Root Token:' /tmp/vault-keys.txt | cut -d: -f2 | tr -d ' ')
    vault operator unseal $VAULT_UNSEAL_KEY
    export VAULT_TOKEN=$VAULT_ROOT_TOKEN
fi

# Configure authentication methods
echo "Configuring GitHub OAuth authentication..."

# Enable OIDC auth for GitHub OAuth
vault auth enable oidc 2>/dev/null || echo "OIDC already enabled"

# Configure GitHub OIDC
vault write auth/oidc/config \
    oidc_discovery_url="https://github.com" \
    oidc_client_id="${GITHUB_OAUTH_CLIENT_ID}" \
    oidc_client_secret="${GITHUB_OAUTH_CLIENT_SECRET}" \
    default_role="github-oauth" \
    oidc_scopes="user:email"

# Create OIDC role for GitHub
vault write auth/oidc/role/github-oauth \
    bound_audiences="${GITHUB_OAUTH_CLIENT_ID}" \
    allowed_redirect_uris="https://keys.bryanwills.dev/ui/vault/auth/oidc/oidc/callback" \
    user_claim="sub" \
    policies="default" \
    oidc_scopes="user:email"

echo "Vault configuration complete!"
echo "Access at: https://keys.bryanwills.dev"

# Keep Vault running in foreground
wait $VAULT_PID
