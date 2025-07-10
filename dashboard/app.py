import os
import asyncio
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
import httpx

def get_secret(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return default

TELEGRAM_TOKEN = get_secret(os.environ.get('TELEGRAM_TOKEN_FILE', '/run/secrets/telegram_token'))

# Список сервисов для мониторинга (название: url healthcheck)
SERVICES = {
    'scrapy-bot': os.environ.get('SCRAPY_BOT_URL', 'http://scrapy-bot:8000/health'),
    'kafka-bot': os.environ.get('KAFKA_BOT_URL', 'http://kafka-bot:8000/health'),
    'ai-bot': os.environ.get('AI_BOT_URL', 'http://ai-bot:8000/health'),
    'wp-publisher': os.environ.get('WP_PUBLISHER_URL', 'http://wp-publisher:8081/docs'),
}

app = FastAPI()
templates = Jinja2Templates(directory="templates")

# Асинхронно опрашиваем все сервисы
async def get_statuses():
    statuses = {}
    async with httpx.AsyncClient(timeout=2) as client:
        for name, url in SERVICES.items():
            try:
                resp = await client.get(url)
                if resp.status_code == 200:
                    data = resp.json() if resp.headers.get('content-type','').startswith('application/json') else {}
                    statuses[name] = {
                        'status': '🟢 OK',
                        'uptime': data.get('uptime', '—'),
                        'details': data.get('details', resp.text)
                    }
                else:
                    statuses[name] = {'status': '🔴 DOWN', 'uptime': '—', 'details': f'HTTP {resp.status_code}'}
            except Exception as e:
                statuses[name] = {'status': '🔴 DOWN', 'uptime': '—', 'details': str(e)}
    return statuses

@app.get('/', response_class=HTMLResponse)
async def dashboard(request: Request):
    statuses = await get_statuses()
    return templates.TemplateResponse('index.html', {"request": request, "statuses": statuses})

@app.get('/api/status', response_class=JSONResponse)
async def api_status():
    statuses = await get_statuses()
    return statuses 