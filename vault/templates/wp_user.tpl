{{ with secret "secret/wordpress/credentials" }}
{{ .Data.data.user }}
{{ end }} 