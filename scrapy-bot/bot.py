import os

def get_secret(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return default

TELEGRAM_TOKEN = get_secret(os.environ.get('TELEGRAM_TOKEN_FILE', '/run/secrets/telegram_token'))

# ... остальной код бота ... 