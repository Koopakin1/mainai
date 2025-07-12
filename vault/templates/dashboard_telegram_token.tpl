{{ with secret "secret/dashboard/telegram_token" }}
{{ .Data.data.token }}
{{ end }} 