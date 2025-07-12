{{ with secret "secret/wordpress/credentials" }}
{{ .Data.data.url }}
{{ end }} 