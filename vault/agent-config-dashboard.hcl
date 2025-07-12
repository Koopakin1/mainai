pid_file = "/vault/agent.pid"

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path = "/vault/roleid"
      secret_id_file_path = "/vault/secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

template {
  source      = "/vault/templates/dashboard_telegram_token.tpl"
  destination = "/vault/secrets/dashboard_telegram_token"
}

vault {
  address = "http://vault:8200"
}

cache {
  use_auto_auth_token = true
} 