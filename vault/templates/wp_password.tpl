{{ with secret "secret/wordpress/credentials" }}
{{ .Data.data.password }}
{{ end }} 