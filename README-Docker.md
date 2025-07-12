# Запуск ботов в Docker

## Предварительные требования

1. Установленный Docker и Docker Compose
2. Telegram Bot Token (получите у @BotFather)

## Настройка

1. Создайте файл `.env` в корневой директории проекта:

```bash
# Telegram Bot Token (замените на ваш токен)
TELEGRAM_TOKEN=ВАШ_ТОКЕН_ТУТ

# WordPress настройки
WORDPRESS_URL=http://localhost
WORDPRESS_USERNAME=admin
WORDPRESS_PASSWORD=password

# Kafka настройки
KAFKA_BOOTSTRAP_SERVERS=kafka:29092
```

## Запуск всех сервисов

```bash
# Запуск всех ботов и сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка всех сервисов
docker-compose down
```

## Запуск отдельных сервисов

```bash
# Только Kafka и Zookeeper
docker-compose up -d zookeeper kafka

# Только AI Bot
docker-compose up -d ai-bot

# Только Dashboard
docker-compose up -d dashboard

# Только WordPress Publisher
docker-compose up -d wp-publisher
```

## Порты сервисов

- **AI Bot**: http://localhost:8000
- **Dashboard**: http://localhost:8080
- **WordPress Publisher**: http://localhost:8081
- **Kafka**: localhost:9092
- **Zookeeper**: localhost:2181

## Проверка статуса

```bash
# Статус всех контейнеров
docker-compose ps

# Логи конкретного сервиса
docker-compose logs ai-bot
docker-compose logs kafka-bot
docker-compose logs scrapy-bot
docker-compose logs dashboard
docker-compose logs wp-publisher
```

## Пересборка образов

```bash
# Пересборка всех образов
docker-compose build --no-cache

# Пересборка конкретного сервиса
docker-compose build ai-bot
```

## Очистка

```bash
# Остановка и удаление контейнеров
docker-compose down

# Удаление образов
docker-compose down --rmi all

# Удаление volumes (данные будут потеряны)
docker-compose down -v
``` 