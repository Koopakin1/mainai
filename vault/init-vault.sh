#!/bin/bash

# Скрипт для инициализации Vault и настройки секретов
# Запуск: ./init-vault.sh

echo "🔐 Инициализация Vault..."

# Ждем запуска Vault
echo "⏳ Ожидание запуска Vault..."
sleep 10

# Проверяем доступность Vault
until vault status; do
    echo "Vault еще не готов, ждем..."
    sleep 5
done

echo "✅ Vault готов!"

# Включаем KV secrets engine
echo "🔧 Настройка KV secrets engine..."
vault secrets enable -path=secret kv-v2

# Создаем политику для ботов
echo "📋 Создание политики для ботов..."
cat > /tmp/bot-policy.hcl << EOF
# AI Bot секреты
path "secret/data/ai-bot/telegram_token" {
  capabilities = ["read"]
}

path "secret/data/ai-bot/openai_api_key" {
  capabilities = ["read"]
}

# Kafka Bot секреты
path "secret/data/kafka-bot/telegram_token" {
  capabilities = ["read"]
}

# Scrapy Bot секреты
path "secret/data/scrapy-bot/telegram_token" {
  capabilities = ["read"]
}

# Dashboard секреты
path "secret/data/dashboard/telegram_token" {
  capabilities = ["read"]
}

# WordPress Publisher секреты
path "secret/data/wordpress/credentials" {
  capabilities = ["read"]
}
EOF

vault policy write bot-policy /tmp/bot-policy.hcl

# Включаем AppRole auth method
echo "🔑 Настройка AppRole auth method..."
vault auth enable approle

# Создаем роль для ботов
echo "👤 Создание роли для ботов..."
vault write auth/approle/role/bot-role \
    token_policies="bot-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# Получаем Role ID и Secret ID
echo "🔑 Получение учетных данных..."
ROLE_ID=$(vault read -format=json auth/approle/role/bot-role/role-id | jq -r '.data.role_id')
SECRET_ID=$(vault write -format=json -f auth/approle/role/bot-role/secret-id | jq -r '.data.secret_id')

echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"

# Сохраняем учетные данные в файлы
echo "$ROLE_ID" > /vault/roleid
echo "$SECRET_ID" > /vault/secretid

# Записываем секреты для всех сервисов в Vault
echo "📱 Сохранение секретов для всех сервисов в Vault..."

# AI Bot секреты
vault kv put secret/ai-bot/telegram_token token="ВАШ_AI_BOT_ТОКЕН_ТУТ"
vault kv put secret/ai-bot/openai_api_key key="ВАШ_OPENAI_API_КЛЮЧ_ТУТ"

# Kafka Bot секреты
vault kv put secret/kafka-bot/telegram_token token="ВАШ_KAFKA_BOT_ТОКЕН_ТУТ"

# Scrapy Bot секреты
vault kv put secret/scrapy-bot/telegram_token token="ВАШ_SCRAPY_BOT_ТОКЕН_ТУТ"

# Dashboard секреты
vault kv put secret/dashboard/telegram_token token="ВАШ_DASHBOARD_ТОКЕН_ТУТ"

# WordPress Publisher секреты
vault kv put secret/wordpress/credentials url="http://localhost" user="admin" password="password"

echo "✅ Vault инициализирован!"
echo "📝 Не забудьте заменить все токены на реальные значения!"
echo "📋 Список секретов для настройки:"
echo "  - AI Bot: secret/ai-bot/telegram_token, secret/ai-bot/openai_api_key"
echo "  - Kafka Bot: secret/kafka-bot/telegram_token"
echo "  - Scrapy Bot: secret/scrapy-bot/telegram_token"
echo "  - Dashboard: secret/dashboard/telegram_token"
echo "  - WordPress Publisher: secret/wordpress/credentials" 