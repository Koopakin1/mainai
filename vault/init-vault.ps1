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

# Записываем Telegram токен в Vault
Write-Host "📱 Сохранение Telegram токена в Vault..." -ForegroundColor Yellow
docker exec vault vault kv put secret/telegram/token token="ВАШ_ТОКЕН_ТУТ"

# Записываем WordPress учетные данные в Vault
Write-Host "📝 Сохранение WordPress учетных данных в Vault..." -ForegroundColor Yellow
docker exec vault vault kv put secret/wordpress/credentials url="http://localhost" user="admin" password="password"

Write-Host "`n✅ Vault инициализирован!" -ForegroundColor Green
Write-Host "📝 Не забудьте заменить 'ВАШ_ТОКЕН_ТУТ' на реальный токен!" -ForegroundColor Yellow
Write-Host "📝 Обновите WordPress учетные данные при необходимости!" -ForegroundColor Yellow
Write-Host "🔗 Vault UI доступен по адресу: http://localhost:8200" -ForegroundColor Cyan
Write-Host "🔑 Root Token: myroot" -ForegroundColor Cyan 