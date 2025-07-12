# Скрипт для управления секретами всех сервисов
# Запуск: .\manage-secrets.ps1

Write-Host "🔐 Управление секретами всех сервисов" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Проверяем, что Vault запущен
try {
    $vaultStatus = docker exec vault vault status
    Write-Host "✅ Vault доступен" -ForegroundColor Green
} catch {
    Write-Host "❌ Vault не доступен. Запустите сначала: .\start-bots.ps1" -ForegroundColor Red
    exit 1
}

# Функция для отображения секрета
function Show-Secret {
    param($Service, $SecretPath, $Description)
    Write-Host "`n📋 $Service - $Description" -ForegroundColor Cyan
    Write-Host "Путь: $SecretPath" -ForegroundColor Gray
    try {
        $result = docker exec vault vault kv get $SecretPath
        Write-Host "Значение: " -ForegroundColor Yellow -NoNewline
        Write-Host $result -ForegroundColor White
    } catch {
        Write-Host "❌ Ошибка получения секрета" -ForegroundColor Red
    }
}

# Функция для обновления секрета
function Update-Secret {
    param($Service, $SecretPath, $Key, $Description)
    Write-Host "`n🔄 Обновление $Service - $Description" -ForegroundColor Cyan
    $newValue = Read-Host "Введите новое значение для $Key"
    if ($newValue -and $newValue -ne "") {
        try {
            docker exec vault vault kv put $SecretPath $Key="$newValue"
            Write-Host "✅ Секрет обновлен" -ForegroundColor Green
        } catch {
            Write-Host "❌ Ошибка обновления секрета" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  Значение не изменено" -ForegroundColor Yellow
    }
}

# Главное меню
do {
    Write-Host "`n🎯 Выберите действие:" -ForegroundColor Magenta
    Write-Host "1. Просмотреть все секреты" -ForegroundColor White
    Write-Host "2. Обновить AI Bot секреты" -ForegroundColor White
    Write-Host "3. Обновить Kafka Bot секен" -ForegroundColor White
    Write-Host "4. Обновить Scrapy Bot секреты" -ForegroundColor White
    Write-Host "5. Обновить Dashboard секреты" -ForegroundColor White
    Write-Host "6. Обновить WordPress секреты" -ForegroundColor White
    Write-Host "7. Обновить все секреты" -ForegroundColor White
    Write-Host "0. Выход" -ForegroundColor White
    
    $choice = Read-Host "`nВведите номер действия"
    
    switch ($choice) {
        "1" {
            Write-Host "`n📋 Просмотр всех секретов:" -ForegroundColor Green
            Show-Secret "AI Bot" "secret/ai-bot/telegram_token" "Telegram Token"
            Show-Secret "AI Bot" "secret/ai-bot/openai_api_key" "OpenAI API Key"
            Show-Secret "Kafka Bot" "secret/kafka-bot/telegram_token" "Telegram Token"
            Show-Secret "Scrapy Bot" "secret/scrapy-bot/telegram_token" "Telegram Token"
            Show-Secret "Dashboard" "secret/dashboard/telegram_token" "Telegram Token"
            Show-Secret "WordPress" "secret/wordpress/credentials" "Credentials"
        }
        "2" {
            Write-Host "`n🤖 Обновление AI Bot секретов:" -ForegroundColor Green
            Update-Secret "AI Bot" "secret/ai-bot/telegram_token" "token" "Telegram Token"
            Update-Secret "AI Bot" "secret/ai-bot/openai_api_key" "key" "OpenAI API Key"
        }
        "3" {
            Write-Host "`n📨 Обновление Kafka Bot секретов:" -ForegroundColor Green
            Update-Secret "Kafka Bot" "secret/kafka-bot/telegram_token" "token" "Telegram Token"
        }
        "4" {
            Write-Host "`n🕷️ Обновление Scrapy Bot секретов:" -ForegroundColor Green
            Update-Secret "Scrapy Bot" "secret/scrapy-bot/telegram_token" "token" "Telegram Token"
        }
        "5" {
            Write-Host "`n📊 Обновление Dashboard секретов:" -ForegroundColor Green
            Update-Secret "Dashboard" "secret/dashboard/telegram_token" "token" "Telegram Token"
        }
        "6" {
            Write-Host "`n📝 Обновление WordPress секретов:" -ForegroundColor Green
            $url = Read-Host "Введите WordPress URL"
            $user = Read-Host "Введите WordPress пользователя"
            $password = Read-Host "Введите WordPress пароль" -AsSecureString
            $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
            
            if ($url -and $user -and $plainPassword) {
                try {
                    docker exec vault vault kv put secret/wordpress/credentials url="$url" user="$user" password="$plainPassword"
                    Write-Host "✅ WordPress секреты обновлены" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Ошибка обновления секретов" -ForegroundColor Red
                }
            } else {
                Write-Host "⚠️  Не все значения указаны" -ForegroundColor Yellow
            }
        }
        "7" {
            Write-Host "`n🔄 Обновление всех секретов:" -ForegroundColor Green
            Write-Host "Это обновит все секреты всех сервисов" -ForegroundColor Yellow
            $confirm = Read-Host "Продолжить? (y/N)"
            if ($confirm -eq "y" -or $confirm -eq "Y") {
                Update-Secret "AI Bot" "secret/ai-bot/telegram_token" "token" "Telegram Token"
                Update-Secret "AI Bot" "secret/ai-bot/openai_api_key" "key" "OpenAI API Key"
                Update-Secret "Kafka Bot" "secret/kafka-bot/telegram_token" "token" "Telegram Token"
                Update-Secret "Scrapy Bot" "secret/scrapy-bot/telegram_token" "token" "Telegram Token"
                Update-Secret "Dashboard" "secret/dashboard/telegram_token" "token" "Telegram Token"
                
                $url = Read-Host "Введите WordPress URL"
                $user = Read-Host "Введите WordPress пользователя"
                $password = Read-Host "Введите WordPress пароль" -AsSecureString
                $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
                
                if ($url -and $user -and $plainPassword) {
                    docker exec vault vault kv put secret/wordpress/credentials url="$url" user="$user" password="$plainPassword"
                }
                
                Write-Host "✅ Все секреты обновлены" -ForegroundColor Green
            }
        }
        "0" {
            Write-Host "`n👋 До свидания!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "❌ Неверный выбор. Попробуйте снова." -ForegroundColor Red
        }
    }
} while ($choice -ne "0")

Write-Host "`n💡 Полезные команды:" -ForegroundColor Cyan
Write-Host "docker exec vault vault kv list secret/" -ForegroundColor White
Write-Host "docker exec vault vault kv get secret/ai-bot/telegram_token" -ForegroundColor White
Write-Host "docker exec vault vault kv put secret/ai-bot/telegram_token token=НОВЫЙ_ТОКЕН" -ForegroundColor White 