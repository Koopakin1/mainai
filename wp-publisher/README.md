# WordPress Publisher Microservice

Микросервис для публикации статей на сайт WordPress через REST API.

## Возможности
- Публикация статьи (заголовок, текст, категории, теги)
- Возврат ссылки на опубликованную статью

## Переменные окружения
- WP_URL — адрес сайта WordPress (например, https://example.com)
- WP_USER — логин пользователя WordPress
- WP_PASSWORD — пароль или application password

## Запуск
1. Укажите переменные окружения
2. Соберите и запустите:
   ```
   docker-compose up --build -d
   ```

## Пример запроса
POST /publish
```
{
  "title": "Заголовок статьи",
  "content": "Текст статьи",
  "categories": [1],
  "tags": [2,3]
}
``` 