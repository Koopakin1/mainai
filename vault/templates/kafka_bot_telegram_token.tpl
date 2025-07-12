{{ with secret "secret/kafka-bot/telegram_token" }}
{{ .Data.data.token }}
{{ end }} 