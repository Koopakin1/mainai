import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx

# Переменные окружения для доступа к WordPress
WP_URL = os.environ.get('WP_URL', 'https://example.com')
WP_USER = os.environ.get('WP_USER', 'admin')
WP_PASSWORD = os.environ.get('WP_PASSWORD', 'password')

app = FastAPI()

# Модель запроса
class Article(BaseModel):
    title: str
    content: str
    categories: list[int] = []
    tags: list[int] = []

# Эндпоинт публикации статьи
@app.post('/publish')
async def publish_article(article: Article):
    # Формируем данные для WordPress
    data = {
        'title': article.title,
        'content': article.content,
        'status': 'publish',
        'categories': article.categories,
        'tags': article.tags
    }
    # Публикуем через REST API WordPress
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f'{WP_URL}/wp-json/wp/v2/posts',
                auth=(WP_USER, WP_PASSWORD),
                json=data,
                timeout=10
            )
            if resp.status_code == 201:
                post = resp.json()
                return {'status': 'ok', 'url': post.get('link'), 'id': post.get('id')}
            else:
                raise HTTPException(status_code=resp.status_code, detail=resp.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e)) 