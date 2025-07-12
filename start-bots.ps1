# Скрипт для запуска всех ботов в Docker с Vault
# Запуск: .\start-bots.ps1

Write-Host "🚀 Запуск набора ботов в Docker с Vault..." -ForegroundColor Green

# Проверка наличия Telegram токена
$telegramToken = Read-Host "Введите ваш Telegram Bot Token (или нажмите Enter для пропуска)"

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
path "secret/data/telegram/token" {
  capabilities = ["read"]
}

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

# Записываем Telegram токен в Vault
if ($telegramToken -and $telegramToken -ne "") {
    Write-Host "📱 Настройка Telegram токена в Vault..." -ForegroundColor Cyan
    docker exec vault vault kv put secret/telegram/token token="$telegramToken"
} else {
    Write-Host "⚠️  Telegram токен не указан. Используется значение по умолчанию." -ForegroundColor Yellow
    docker exec vault vault kv put secret/telegram/token token="ВАШ_ТОКЕН_ТУТ"
}

# Записываем WordPress учетные данные в Vault
Write-Host "📝 Настройка WordPress учетных данных в Vault..." -ForegroundColor Cyan
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
Write-Host "docker exec vault vault kv get secret/telegram/token" -ForegroundColor White
Write-Host "docker exec vault vault kv put secret/telegram/token token=НОВЫЙ_ТОКЕН" -ForegroundColor White
Write-Host "docker exec vault vault kv get secret/wordpress/credentials" -ForegroundColor White
Write-Host "docker exec vault vault kv put secret/wordpress/credentials url=НОВЫЙ_URL user=НОВЫЙ_ПОЛЬЗОВАТЕЛЬ password=НОВЫЙ_ПАРОЛЬ" -ForegroundColor White 