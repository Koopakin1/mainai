# Скрипт для запуска всех ботов в Docker с Vault
# Запуск: .\start-bots.ps1

Write-Host "🚀 Запуск набора ботов в Docker с Vault..." -ForegroundColor Green

# Проверка наличия токенов
Write-Host "📱 Введите токены для всех сервисов:" -ForegroundColor Cyan
$aiBotToken = Read-Host "AI Bot Telegram Token (или нажмите Enter для пропуска)"
$kafkaBotToken = Read-Host "Kafka Bot Telegram Token (или нажмите Enter для пропуска)"
$scrapyBotToken = Read-Host "Scrapy Bot Telegram Token (или нажмите Enter для пропуска)"
$dashboardToken = Read-Host "Dashboard Telegram Token (или нажмите Enter для пропуска)"
$openaiApiKey = Read-Host "OpenAI API Key (или нажмите Enter для пропуска)"

# Остановка существующих контейнеров
Write-Host "🛑 Остановка существующих контейнеров..." -ForegroundColor Yellow
docker-compose down

# Сборка образов
Write-Host "🔨 Сборка Docker образов..." -ForegroundColor Yellow
docker-compose build

# Запуск Vault и Kafka
Write-Host "🔐 Запуск Vault и Kafka..." -ForegroundColor Green
docker-compose up -d vault zookeeper kafka

# Ожидание запуска Vault
Write-Host "⏳ Ожидание запуска Vault..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Инициализация Vault
Write-Host "🔧 Инициализация Vault..." -ForegroundColor Yellow

# Включаем KV secrets engine
docker exec vault vault secrets enable -path=secret kv-v2

# Создаем политику для ботов
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
docker exec vault vault auth enable approle

# Создаем роль для ботов
docker exec vault vault write auth/approle/role/bot-role token_policies="bot-policy" token_ttl=1h token_max_ttl=4h

# Получаем Role ID и Secret ID
$roleId = docker exec vault vault read -format=json auth/approle/role/bot-role/role-id | ConvertFrom-Json
$secretId = docker exec vault vault write -format=json -f auth/approle/role/bot-role/secret-id | ConvertFrom-Json

$roleIdValue = $roleId.data.role_id
$secretIdValue = $secretId.data.secret_id

# Сохраняем учетные данные в файлы
$roleIdValue | Out-File -FilePath "vault\roleid" -Encoding UTF8
$secretIdValue | Out-File -FilePath "vault\secretid" -Encoding UTF8

# Записываем секреты для всех сервисов в Vault
Write-Host "📱 Настройка секретов для всех сервисов в Vault..." -ForegroundColor Cyan

# AI Bot секреты
if ($aiBotToken -and $aiBotToken -ne "") {
    docker exec vault vault kv put secret/ai-bot/telegram_token token="$aiBotToken"
} else {
    docker exec vault vault kv put secret/ai-bot/telegram_token token="ВАШ_AI_BOT_ТОКЕН_ТУТ"
}

if ($openaiApiKey -and $openaiApiKey -ne "") {
    docker exec vault vault kv put secret/ai-bot/openai_api_key key="$openaiApiKey"
} else {
    docker exec vault vault kv put secret/ai-bot/openai_api_key key="ВАШ_OPENAI_API_КЛЮЧ_ТУТ"
}

# Kafka Bot секреты
if ($kafkaBotToken -and $kafkaBotToken -ne "") {
    docker exec vault vault kv put secret/kafka-bot/telegram_token token="$kafkaBotToken"
} else {
    docker exec vault vault kv put secret/kafka-bot/telegram_token token="ВАШ_KAFKA_BOT_ТОКЕН_ТУТ"
}

# Scrapy Bot секреты
if ($scrapyBotToken -and $scrapyBotToken -ne "") {
    docker exec vault vault kv put secret/scrapy-bot/telegram_token token="$scrapyBotToken"
} else {
    docker exec vault vault kv put secret/scrapy-bot/telegram_token token="ВАШ_SCRAPY_BOT_ТОКЕН_ТУТ"
}

# Dashboard секреты
if ($dashboardToken -and $dashboardToken -ne "") {
    docker exec vault vault kv put secret/dashboard/telegram_token token="$dashboardToken"
} else {
    docker exec vault vault kv put secret/dashboard/telegram_token token="ВАШ_DASHBOARD_ТОКЕН_ТУТ"
}

# WordPress Publisher секреты
docker exec vault vault kv put secret/wordpress/credentials url="http://localhost" user="admin" password="password"

# Запуск всех Vault Agents
Write-Host "🤖 Запуск всех Vault Agents..." -ForegroundColor Green
docker-compose up -d vault-agent-ai-bot vault-agent-kafka-bot vault-agent-scrapy-bot vault-agent-dashboard vault-agent-wp-publisher

# Ожидание запуска Vault Agents
Write-Host "⏳ Ожидание запуска Vault Agents..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Запуск всех ботов и сервисов
Write-Host "🚀 Запуск всех ботов и сервисов..." -ForegroundColor Green
docker-compose up -d ai-bot kafka-bot scrapy-bot dashboard wp-publisher

# Ожидание запуска всех сервисов
Write-Host "⏳ Ожидание запуска всех сервисов..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Проверка статуса
Write-Host "📊 Статус контейнеров:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`n🎉 Все боты и сервисы запущены с Vault!" -ForegroundColor Green
Write-Host "🔐 Vault UI: http://localhost:8200 (Root Token: myroot)" -ForegroundColor White
Write-Host "📱 AI Bot: http://localhost:8000" -ForegroundColor White
Write-Host "📊 Dashboard: http://localhost:8080" -ForegroundColor White
Write-Host "📝 WordPress Publisher: http://localhost:8081" -ForegroundColor White
Write-Host "📨 Kafka: localhost:9092" -ForegroundColor White

Write-Host "`n📋 Для просмотра логов используйте:" -ForegroundColor Cyan
Write-Host "docker-compose logs -f" -ForegroundColor White

Write-Host "`n🛑 Для остановки используйте:" -ForegroundColor Cyan
Write-Host "docker-compose down" -ForegroundColor White

Write-Host "`n🔧 Для управления секретами в Vault:" -ForegroundColor Cyan
Write-Host ".\manage-secrets.ps1" -ForegroundColor White
Write-Host "docker exec vault vault kv get secret/ai-bot/telegram_token" -ForegroundColor White
Write-Host "docker exec vault vault kv put secret/ai-bot/telegram_token token=НОВЫЙ_ТОКЕН" -ForegroundColor White
Write-Host "docker exec vault vault kv get secret/ai-bot/openai_api_key" -ForegroundColor White
Write-Host "docker exec vault vault kv put secret/ai-bot/openai_api_key key=НОВЫЙ_КЛЮЧ" -ForegroundColor White 