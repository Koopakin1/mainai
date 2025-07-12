{{ with secret "secret/ai-bot/openai_api_key" }}
{{ .Data.data.key }}
{{ end }} 