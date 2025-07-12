{{ with secret "secret/ai-bot/telegram_token" }}
{{ .Data.data.token }}
{{ end }} 