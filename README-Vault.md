# Запуск ботов с Vault для управления секретами

## 🔐 Что такое Vault Agent?

Vault Agent - это легковесный клиент, который:
- Запускается как сайдкар-контейнер рядом с основным приложением
- Извлекает секреты из Vault
- Кэширует их локально
- Предоставляет основному приложению через файлы или переменные окружения

## 🚀 Быстрый запуск

### 1. Запуск всех сервисов
```powershell
.\start-bots.ps1
```

### 2. Управление секретами
```powershell
.\manage-secrets.ps1
```

### 2. Ручной запуск
```bash
# Запуск Vault и инфраструктуры
docker-compose up -d vault zookeeper kafka

# Инициализация Vault
.\vault\init-vault.ps1

# Запуск всех Vault Agents
docker-compose up -d vault-agent-ai-bot vault-agent-kafka-bot vault-agent-scrapy-bot vault-agent-dashboard vault-agent-wp-publisher

# Запуск всех ботов и сервисов
docker-compose up -d ai-bot kafka-bot scrapy-bot dashboard wp-publisher
```

## 🔧 Настройка секретов

### 1. Через Vault UI
- Откройте http://localhost:8200
- Войдите с токеном: `myroot`
- Перейдите в `secret/data/telegram/token` для Telegram токена
- Перейдите в `secret/data/wordpress/credentials` для WordPress учетных данных

### 2. Через командную строку
```bash
# AI Bot секреты
docker exec vault vault kv get secret/ai-bot/telegram_token
docker exec vault vault kv get secret/ai-bot/openai_api_key
docker exec vault vault kv put secret/ai-bot/telegram_token token="НОВЫЙ_ТОКЕН"
docker exec vault vault kv put secret/ai-bot/openai_api_key key="НОВЫЙ_КЛЮЧ"

# Kafka Bot секреты
docker exec vault vault kv get secret/kafka-bot/telegram_token
docker exec vault vault kv put secret/kafka-bot/telegram_token token="НОВЫЙ_ТОКЕН"

# Scrapy Bot секреты
docker exec vault vault kv get secret/scrapy-bot/telegram_token
docker exec vault vault kv put secret/scrapy-bot/telegram_token token="НОВЫЙ_ТОКЕН"

# Dashboard секреты
docker exec vault vault kv get secret/dashboard/telegram_token
docker exec vault vault kv put secret/dashboard/telegram_token token="НОВЫЙ_ТОКЕН"

# WordPress Publisher секреты
docker exec vault vault kv get secret/wordpress/credentials
docker exec vault vault kv put secret/wordpress/credentials url="http://example.com" user="admin" password="newpassword"
```

## 📁 Структура Vault

```
vault/
├── agent-config-ai-bot.hcl         # Конфигурация Vault Agent для AI Bot
├── agent-config-kafka-bot.hcl      # Конфигурация Vault Agent для Kafka Bot
├── agent-config-scrapy-bot.hcl     # Конфигурация Vault Agent для Scrapy Bot
├── agent-config-dashboard.hcl      # Конфигурация Vault Agent для Dashboard
├── agent-config-wp-publisher.hcl   # Конфигурация Vault Agent для WordPress Publisher
├── templates/
│   ├── ai_bot_telegram_token.tpl   # Шаблон для AI Bot Telegram токена
│   ├── ai_bot_openai_api_key.tpl   # Шаблон для AI Bot OpenAI API ключа
│   ├── kafka_bot_telegram_token.tpl # Шаблон для Kafka Bot Telegram токена
│   ├── scrapy_bot_telegram_token.tpl # Шаблон для Scrapy Bot Telegram токена
│   ├── dashboard_telegram_token.tpl # Шаблон для Dashboard Telegram токена
│   ├── wp_url.tpl                  # Шаблон для извлечения WordPress URL
│   ├── wp_user.tpl                 # Шаблон для извлечения WordPress пользователя
│   └── wp_password.tpl             # Шаблон для извлечения WordPress пароля
├── secrets/                        # Директория для извлеченных секретов
├── init-vault.sh                   # Скрипт инициализации (Linux)
└── init-vault.ps1                  # Скрипт инициализации (Windows)
```

## 🔐 Структура секретов в Vault

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

## 🔑 Аутентификация

### AppRole метод
- **Role ID**: Автоматически генерируется при инициализации
- **Secret ID**: Автоматически генерируется при инициализации
- **Политика**: `bot-policy` - разрешает чтение Telegram токена и WordPress учетных данных

### Политика безопасности
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

## 📊 Мониторинг

### Проверка статуса всех Vault Agents
```bash
# Логи Vault Agent для AI Bot
docker logs vault-agent-ai-bot

# Логи Vault Agent для Kafka Bot
docker logs vault-agent-kafka-bot

# Логи Vault Agent для Scrapy Bot
docker logs vault-agent-scrapy-bot

# Логи Vault Agent для Dashboard
docker logs vault-agent-dashboard

# Логи Vault Agent для WordPress Publisher
docker logs vault-agent-wp-publisher
```

### Проверка извлеченных секретов
```bash
# Проверка файлов с секретами
cat vault/secrets/telegram_token
cat vault/secrets/wp_url
cat vault/secrets/wp_user
cat vault/secrets/wp_password
```

## 🔄 Обновление секретов

### Автоматическое обновление
Vault Agents автоматически обновляют секреты при их изменении в Vault.

### Ручное обновление
```bash
# Обновление Telegram токена
docker exec vault vault kv put secret/telegram/token token="НОВЫЙ_ТОКЕН"

# Обновление WordPress учетных данных
docker exec vault vault kv put secret/wordpress/credentials url="http://example.com" user="admin" password="newpassword"

# Перезапуск Vault Agent (если нужно)
docker restart vault-agent-ai-bot
```

## 🛡️ Безопасность

### Преимущества использования Vault:
1. **Централизованное управление секретами**
2. **Шифрование в состоянии покоя**
3. **Контроль доступа на основе политик**
4. **Аудит и логирование**
5. **Автоматическая ротация секретов**

### Рекомендации:
- Измените root токен в продакшене
- Используйте TLS для связи с Vault
- Настройте резервное копирование Vault
- Регулярно ротируйте секреты

## 🚨 Устранение неполадок

### Vault не запускается
```bash
# Проверка логов
docker logs vault

# Проверка портов
netstat -an | findstr 8200
```

### Vault Agent не может подключиться
```bash
# Проверка сети
docker network ls
docker network inspect mainai_bot-network

# Проверка доступности Vault
docker exec vault-agent-ai-bot vault status
```

### Секреты не извлекаются
```bash
# Проверка конфигурации
docker exec vault-agent-ai-bot cat /vault/config/agent.hcl

# Проверка аутентификации
docker exec vault-agent-ai-bot vault token lookup
```

## 📚 Дополнительные ресурсы

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Agent](https://www.vaultproject.io/docs/agent)
- [AppRole Auth Method](https://www.vaultproject.io/docs/auth/approle)
- [KV Secrets Engine](https://www.vaultproject.io/docs/secrets/kv) 