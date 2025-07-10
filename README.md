# Telegram Scrapy Bot

Бот для управления Scrapy через Telegram с подробными комментариями на русском языке.

# Запуск в Docker

1. Соберите контейнер:
   ```
   docker build -t scrapy-telegram-bot .
   ```
2. Запустите контейнер:
   ```
   docker run -d --name scrapy_telegram_bot -e TELEGRAM_TOKEN=ВАШ_ТОКЕН_ТУТ -v $(pwd)/config.db:/app/config.db scrapy-telegram-bot
   ```

Или используйте docker-compose:

```
docker-compose up --build -d
```

**Не забудьте указать свой TELEGRAM_TOKEN!**

# Использование HashiCorp Vault для секретов

Можно хранить токен Telegram и другие секреты в HashiCorp Vault.

Пример переменных окружения для docker-compose:

```
  environment:
    - VAULT_ADDR=http://vault:8200
    - VAULT_TOKEN=ваш_vault_token
    - VAULT_SECRET_PATH=secret/data/telegram
    - VAULT_SECRET_KEY=TELEGRAM_TOKEN
```

Если переменные VAULT_ADDR и VAULT_TOKEN заданы, бот получит токен из Vault.
Если нет — будет использовать TELEGRAM_TOKEN из переменных окружения.