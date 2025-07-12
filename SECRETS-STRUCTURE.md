# 🔐 Структура секретов для всех сервисов

## 📋 Обзор

Теперь каждый сервис имеет свои собственные секреты в Vault, что обеспечивает:
- ✅ Изоляцию секретов между сервисами
- ✅ Безопасность (каждый сервис видит только свои секреты)
- ✅ Простоту управления
- ✅ Масштабируемость

## 🏗️ Структура секретов в Vault

```
secret/
├── ai-bot/
│   ├── telegram_token              # Telegram токен для AI Bot
│   └── openai_api_key              # OpenAI API ключ для AI Bot
├── kafka-bot/
│   └── telegram_token              # Telegram токен для Kafka Bot
├── scrapy-bot/
│   └── telegram_token              # Telegram токен для Scrapy Bot
├── dashboard/
│   └── telegram_token              # Telegram токен для Dashboard
└── wordpress/
    └── credentials                 # WordPress учетные данные
```

## 🤖 Сервисы и их секреты

### 1. AI Bot (`ai-bot`)
- **Telegram Token**: `secret/ai-bot/telegram_token`
- **OpenAI API Key**: `secret/ai-bot/openai_api_key`
- **Файлы секретов**: `/app/secrets/ai_bot_telegram_token`, `/app/secrets/ai_bot_openai_api_key`

### 2. Kafka Bot (`kafka-bot`)
- **Telegram Token**: `secret/kafka-bot/telegram_token`
- **Файлы секретов**: `/app/secrets/kafka_bot_telegram_token`

### 3. Scrapy Bot (`scrapy-bot`)
- **Telegram Token**: `secret/scrapy-bot/telegram_token`
- **Файлы секретов**: `/app/secrets/scrapy_bot_telegram_token`

### 4. Dashboard (`dashboard`)
- **Telegram Token**: `secret/dashboard/telegram_token`
- **Файлы секретов**: `/app/secrets/dashboard_telegram_token`

### 5. WordPress Publisher (`wp-publisher`)
- **Credentials**: `secret/wordpress/credentials` (url, user, password)
- **Файлы секретов**: `/app/secrets/wp_url`, `/app/secrets/wp_user`, `/app/secrets/wp_password`

## 🔧 Управление секретами

### Автоматическое управление
```powershell
# Запуск с настройкой всех секретов
.\start-bots.ps1

# Интерактивное управление секретами
.\manage-secrets.ps1
```

### Ручное управление через Vault CLI
```bash
# Просмотр секретов
docker exec vault vault kv get secret/ai-bot/telegram_token
docker exec vault vault kv get secret/ai-bot/openai_api_key
docker exec vault vault kv get secret/kafka-bot/telegram_token
docker exec vault vault kv get secret/scrapy-bot/telegram_token
docker exec vault vault kv get secret/dashboard/telegram_token
docker exec vault vault kv get secret/wordpress/credentials

# Обновление секретов
docker exec vault vault kv put secret/ai-bot/telegram_token token="НОВЫЙ_ТОКЕН"
docker exec vault vault kv put secret/ai-bot/openai_api_key key="НОВЫЙ_КЛЮЧ"
docker exec vault vault kv put secret/kafka-bot/telegram_token token="НОВЫЙ_ТОКЕН"
docker exec vault vault kv put secret/scrapy-bot/telegram_token token="НОВЫЙ_ТОКЕН"
docker exec vault vault kv put secret/dashboard/telegram_token token="НОВЫЙ_ТОКЕН"
docker exec vault vault kv put secret/wordpress/credentials url="URL" user="USER" password="PASSWORD"
```

### Управление через Vault UI
1. Откройте http://localhost:8200
2. Войдите с токеном: `myroot`
3. Перейдите в раздел `secret/data/`
4. Выберите нужный сервис и секрет

## 📁 Структура файлов

### Шаблоны Vault Agent
```
vault/templates/
├── ai_bot_telegram_token.tpl       # AI Bot Telegram токен
├── ai_bot_openai_api_key.tpl       # AI Bot OpenAI API ключ
├── kafka_bot_telegram_token.tpl    # Kafka Bot Telegram токен
├── scrapy_bot_telegram_token.tpl   # Scrapy Bot Telegram токен
├── dashboard_telegram_token.tpl    # Dashboard Telegram токен
├── wp_url.tpl                      # WordPress URL
├── wp_user.tpl                     # WordPress пользователь
└── wp_password.tpl                 # WordPress пароль
```

### Конфигурации Vault Agent
```
vault/
├── agent-config-ai-bot.hcl         # AI Bot конфигурация
├── agent-config-kafka-bot.hcl      # Kafka Bot конфигурация
├── agent-config-scrapy-bot.hcl     # Scrapy Bot конфигурация
├── agent-config-dashboard.hcl      # Dashboard конфигурация
├── agent-config-wp-publisher.hcl   # WordPress Publisher конфигурация
├── roleid                          # Role ID для аутентификации
├── secretid                        # Secret ID для аутентификации
└── secrets/                        # Извлеченные секреты
```

## 🔐 Политика безопасности

```hcl
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
```

## 🚀 Быстрый старт

### 1. Первый запуск
```powershell
# Запуск всех сервисов с настройкой секретов
.\start-bots.ps1
```

### 2. Управление секретами
```powershell
# Интерактивное управление
.\manage-secrets.ps1
```

### 3. Проверка статуса
```powershell
# Статус контейнеров
docker-compose ps

# Логи Vault
docker logs vault

# Логи Vault Agent
docker logs vault-agent-ai-bot
```

## 🔍 Отладка

### Проверка доступности секретов
```bash
# Проверка файлов секретов в контейнерах
docker exec ai-bot ls -la /app/secrets/
docker exec kafka-bot ls -la /app/secrets/
docker exec scrapy-bot ls -la /app/secrets/
docker exec dashboard ls -la /app/secrets/
docker exec wp-publisher ls -la /app/secrets/
```

### Проверка логов Vault Agent
```bash
# Логи конкретного Vault Agent
docker logs vault-agent-ai-bot
docker logs vault-agent-kafka-bot
docker logs vault-agent-scrapy-bot
docker logs vault-agent-dashboard
docker logs vault-agent-wp-publisher
```

### Проверка аутентификации
```bash
# Проверка токена Vault Agent
docker exec vault-agent-ai-bot vault token lookup
```

## ⚠️ Важные замечания

1. **Безопасность**: Каждый сервис имеет доступ только к своим секретам
2. **Изоляция**: Секреты разных сервисов полностью изолированы
3. **Масштабируемость**: Легко добавлять новые сервисы и секреты
4. **Управление**: Используйте `.\manage-secrets.ps1` для удобного управления
5. **Резервное копирование**: Регулярно делайте бэкапы Vault

## 🔄 Миграция с старой структуры

Если у вас была старая структура с общими секретами:

1. Остановите все сервисы: `docker-compose down`
2. Запустите новую структуру: `.\start-bots.ps1`
3. Настройте секреты через: `.\manage-secrets.ps1`
4. Проверьте работу всех сервисов

Старые секреты (`secret/telegram/token`) больше не используются. 