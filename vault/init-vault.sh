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
path "secret/data/telegram/token" {
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

# Записываем Telegram токен в Vault
echo "📱 Сохранение Telegram токена в Vault..."
vault kv put secret/telegram/token token="ВАШ_ТОКЕН_ТУТ"

echo "✅ Vault инициализирован!"
echo "📝 Не забудьте заменить 'ВАШ_ТОКЕН_ТУТ' на реальный токен!" 