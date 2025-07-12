{{ with secret "secret/scrapy-bot/telegram_token" }}
{{ .Data.data.token }}
{{ end }} 