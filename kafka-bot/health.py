import time
from fastapi import FastAPI
from fastapi.responses import JSONResponse

start_time = time.time()
app = FastAPI()

@app.get("/health")
def health():
    uptime = int(time.time() - start_time)
    return JSONResponse({
        "status": "ok",
        "uptime": f"{uptime // 60} мин {uptime % 60} сек",
        "details": "Kafka Telegram Bot работает"
    }) 