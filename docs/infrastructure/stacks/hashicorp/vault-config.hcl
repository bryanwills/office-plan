ui = true
disable_mlock = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/file"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

# GitHub OAuth configuration
plugin_registry {
  plugin_directory = "/vault/plugins"
}

# Enable audit logging
audit "file" {
  path = "/vault/logs/audit.log"
}
