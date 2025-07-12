{{ with secret "secret/telegram/token" }}
{{ .Data.data.token }}
{{ end }} 