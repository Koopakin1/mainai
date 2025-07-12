# Скрипт для инициализации Vault в Windows
# Запуск: .\vault\init-vault.ps1

Write-Host "🔐 Инициализация Vault..." -ForegroundColor Green

# Проверяем, что Vault контейнер запущен
Write-Host "⏳ Проверка статуса Vault..." -ForegroundColor Yellow
$vaultStatus = docker ps --filter "name=vault" --format "table {{.Names}}\t{{.Status}}"
Write-Host $vaultStatus -ForegroundColor Cyan

# Ждем запуска Vault
Write-Host "⏳ Ожидание запуска Vault..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Проверяем доступность Vault
Write-Host "🔍 Проверка доступности Vault..." -ForegroundColor Yellow
try {
    $vaultStatus = docker exec vault vault status
    Write-Host "✅ Vault готов!" -ForegroundColor Green
} catch {
    Write-Host "❌ Vault не готов. Проверьте логи: docker logs vault" -ForegroundColor Red
    exit 1
}

# Включаем KV secrets engine
Write-Host "🔧 Настройка KV secrets engine..." -ForegroundColor Yellow
docker exec vault vault secrets enable -path=secret kv-v2

# Создаем политику для ботов
Write-Host "📋 Создание политики для ботов..." -ForegroundColor Yellow
$policyContent = @"
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
"@

docker exec vault sh -c "echo '$policyContent' > /tmp/bot-policy.hcl"
docker exec vault vault policy write bot-policy /tmp/bot-policy.hcl

# Включаем AppRole auth method
Write-Host "🔑 Настройка AppRole auth method..." -ForegroundColor Yellow
docker exec vault vault auth enable approle

# Создаем роль для ботов
Write-Host "👤 Создание роли для ботов..." -ForegroundColor Yellow
docker exec vault vault write auth/approle/role/bot-role token_policies="bot-policy" token_ttl=1h token_max_ttl=4h

# Получаем Role ID и Secret ID
Write-Host "🔑 Получение учетных данных..." -ForegroundColor Yellow
$roleId = docker exec vault vault read -format=json auth/approle/role/bot-role/role-id | ConvertFrom-Json
$secretId = docker exec vault vault write -format=json -f auth/approle/role/bot-role/secret-id | ConvertFrom-Json

$roleIdValue = $roleId.data.role_id
$secretIdValue = $secretId.data.secret_id

Write-Host "Role ID: $roleIdValue" -ForegroundColor Cyan
Write-Host "Secret ID: $secretIdValue" -ForegroundColor Cyan

# Сохраняем учетные данные в файлы
Write-Host "💾 Сохранение учетных данных..." -ForegroundColor Yellow
$roleIdValue | Out-File -FilePath "vault\roleid" -Encoding UTF8
$secretIdValue | Out-File -FilePath "vault\secretid" -Encoding UTF8

# Записываем секреты для всех сервисов в Vault
Write-Host "📱 Сохранение секретов для всех сервисов в Vault..." -ForegroundColor Yellow

# AI Bot секреты
docker exec vault vault kv put secret/ai-bot/telegram_token token="ВАШ_AI_BOT_ТОКЕН_ТУТ"
docker exec vault vault kv put secret/ai-bot/openai_api_key key="ВАШ_OPENAI_API_КЛЮЧ_ТУТ"

# Kafka Bot секреты
docker exec vault vault kv put secret/kafka-bot/telegram_token token="ВАШ_KAFKA_BOT_ТОКЕН_ТУТ"

# Scrapy Bot секреты
docker exec vault vault kv put secret/scrapy-bot/telegram_token token="ВАШ_SCRAPY_BOT_ТОКЕН_ТУТ"

# Dashboard секреты
docker exec vault vault kv put secret/dashboard/telegram_token token="ВАШ_DASHBOARD_ТОКЕН_ТУТ"

# WordPress Publisher секреты
docker exec vault vault kv put secret/wordpress/credentials url="http://localhost" user="admin" password="password"

Write-Host "`n✅ Vault инициализирован!" -ForegroundColor Green
Write-Host "📝 Не забудьте заменить все токены на реальные значения!" -ForegroundColor Yellow
Write-Host "📝 Обновите WordPress учетные данные при необходимости!" -ForegroundColor Yellow
Write-Host "🔗 Vault UI доступен по адресу: http://localhost:8200" -ForegroundColor Cyan
Write-Host "`n📋 Список секретов для настройки:" -ForegroundColor Cyan
Write-Host "  - AI Bot: secret/ai-bot/telegram_token, secret/ai-bot/openai_api_key" -ForegroundColor White
Write-Host "  - Kafka Bot: secret/kafka-bot/telegram_token" -ForegroundColor White
Write-Host "  - Scrapy Bot: secret/scrapy-bot/telegram_token" -ForegroundColor White
Write-Host "  - Dashboard: secret/dashboard/telegram_token" -ForegroundColor White
Write-Host "  - WordPress Publisher: secret/wordpress/credentials" -ForegroundColor White
Write-Host "🔑 Root Token: myroot" -ForegroundColor Cyan 