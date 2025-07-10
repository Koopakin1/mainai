import logging  # Для логирования событий
import os  # Для работы с файловой системой
import sqlite3  # Для работы с SQLite (заготовка)
import subprocess  # Для запуска Scrapy как подпроцесса
import requests  # Для работы с HashiCorp Vault
from telegram import (
    Update, InputFile, InlineKeyboardButton, InlineKeyboardMarkup, ReplyKeyboardMarkup, KeyboardButton, ReplyKeyboardRemove
)  # Импортируем необходимые классы
from telegram.ext import (
    ApplicationBuilder, CommandHandler, ContextTypes, ConversationHandler,
    CallbackQueryHandler, MessageHandler, filters
)  # Для создания бота и обработки команд и диалогов

# --- Функция для получения секрета из HashiCorp Vault ---
def get_secret_from_vault(vault_addr, token, secret_path, key):
    """
    Получает секрет из HashiCorp Vault через HTTP API.
    vault_addr: адрес Vault (например, http://vault:8200)
    token: Vault Token (root или с нужными правами)
    secret_path: путь к секрету (например, secret/data/telegram)
    key: ключ внутри секрета (например, TELEGRAM_TOKEN)
    """
    url = f"{vault_addr}/v1/{secret_path}"
    headers = {"X-Vault-Token": token}
    try:
        resp = requests.get(url, headers=headers, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        # Для KV v2 секреты лежат в data->data
        return data["data"]["data"][key]
    except Exception as e:
        logging.error(f"Ошибка получения секрета из Vault: {e}")
        return None

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# --- Получаем токен Telegram из Vault или переменной окружения ---
VAULT_ADDR = os.environ.get('VAULT_ADDR')
VAULT_TOKEN = os.environ.get('VAULT_TOKEN')
VAULT_SECRET_PATH = os.environ.get('VAULT_SECRET_PATH', 'secret/data/telegram')
VAULT_SECRET_KEY = os.environ.get('VAULT_SECRET_KEY', 'TELEGRAM_TOKEN')

if VAULT_ADDR and VAULT_TOKEN:
    TELEGRAM_TOKEN = get_secret_from_vault(VAULT_ADDR, VAULT_TOKEN, VAULT_SECRET_PATH, VAULT_SECRET_KEY)
else:
    TELEGRAM_TOKEN = os.environ.get('TELEGRAM_TOKEN', 'ВАШ_ТОКЕН_ТУТ')

DB_PATH = 'config.db'
SELECT_PARAM, INPUT_VALUE = range(2)

PARAMS = {
    'user_agent': 'User-Agent',
    'download_delay': 'Задержка (DOWNLOAD_DELAY)',
    'proxy': 'Прокси',
}

# --- Главное меню ---
main_menu_keyboard = ReplyKeyboardMarkup(
    [
        [KeyboardButton('▶️ Запустить сбор данных')],
        [KeyboardButton('⚙️ Настройки'), KeyboardButton('📄 Мои параметры')],
        [KeyboardButton('ℹ️ О боте')]
    ], resize_keyboard=True
)

# --- Кнопка возврата ---
back_keyboard = ReplyKeyboardMarkup(
    [[KeyboardButton('⬅️ В главное меню')]], resize_keyboard=True
)

# --- Инициализация базы данных ---
def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            param TEXT,
            value TEXT
        )
    ''')
    conn.commit()
    conn.close()

def save_param(user_id, param, value):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM configs WHERE user_id=? AND param=?', (user_id, param))
    row = cursor.fetchone()
    if row:
        cursor.execute('UPDATE configs SET value=? WHERE id=?', (value, row[0]))
    else:
        cursor.execute('INSERT INTO configs (user_id, param, value) VALUES (?, ?, ?)', (user_id, param, value))
    conn.commit()
    conn.close()

def get_param(user_id, param):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT value FROM configs WHERE user_id=? AND param=?', (user_id, param))
    row = cursor.fetchone()
    conn.close()
    return row[0] if row else None

def get_all_params(user_id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT param, value FROM configs WHERE user_id=?', (user_id,))
    rows = cursor.fetchall()
    conn.close()
    return {param: value for param, value in rows}

# --- Обработчики ---
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        '👋 Привет! Я бот для управления Scrapy.\n\n'
        'Выберите действие с помощью меню ниже.',
        reply_markup=main_menu_keyboard
    )

async def main_menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text('Главное меню:', reply_markup=main_menu_keyboard)

async def about(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        '🤖 <b>Scrapy Telegram Бот</b>\n\n'
        'Этот бот позволяет управлять задачами Scrapy прямо из Telegram.\n'
        'Вы можете запускать сбор данных, настраивать параметры и получать результаты.\n\n'
        'Разработчик: Андрей',
        parse_mode='HTML',
        reply_markup=main_menu_keyboard
    )

async def my_params(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    params = get_all_params(user_id)
    if not params:
        text = 'У вас пока нет сохранённых параметров.'
    else:
        text = 'Ваши параметры:\n'
        for key, name in PARAMS.items():
            value = params.get(key, '—')
            text += f'<b>{name}:</b> {value}\n'
    await update.message.reply_text(text, parse_mode='HTML', reply_markup=main_menu_keyboard)

# --- Диалог настройки параметров ---
async def settings_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    keyboard = [
        [InlineKeyboardButton(name, callback_data=key)] for key, name in PARAMS.items()
    ]
    keyboard.append([InlineKeyboardButton('⬅️ В главное меню', callback_data='back_to_menu')])
    reply_markup = InlineKeyboardMarkup(keyboard)
    if update.message:
        await update.message.reply_text('Выберите параметр для настройки:', reply_markup=reply_markup)
    else:
        await update.callback_query.edit_message_text('Выберите параметр для настройки:', reply_markup=reply_markup)
    return SELECT_PARAM

async def select_param(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    param_key = query.data
    if param_key == 'back_to_menu':
        await query.edit_message_text('Главное меню:')
        await main_menu(query, context)
        return ConversationHandler.END
    context.user_data['param_key'] = param_key
    await query.edit_message_text(f'Введите новое значение для "{PARAMS[param_key]}":', reply_markup=InlineKeyboardMarkup([[InlineKeyboardButton('⬅️ В главное меню', callback_data='back_to_menu')]]))
    return INPUT_VALUE

async def input_value(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    param_key = context.user_data.get('param_key')
    value = update.message.text.strip()
    save_param(user_id, param_key, value)
    await update.message.reply_text(f'Параметр "{PARAMS[param_key]}" сохранён!', reply_markup=main_menu_keyboard)
    return ConversationHandler.END

# --- Запуск Scrapy ---
async def run_scrapy(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    await update.message.reply_text('⏳ Запускаю Scrapy... Пожалуйста, подождите.', reply_markup=ReplyKeyboardRemove())
    output_file = f'result_{user_id}.json'
    user_agent = get_param(user_id, 'user_agent')
    download_delay = get_param(user_id, 'download_delay')
    proxy = get_param(user_id, 'proxy')
    cmd = [
        'python', '-m', 'scrapy', 'crawl', 'example',
        '-o', output_file
    ]
    env = os.environ.copy()
    if user_agent:
        env['SCRAPY_USER_AGENT'] = user_agent
    if download_delay:
        env['SCRAPY_DOWNLOAD_DELAY'] = download_delay
    if proxy:
        env['SCRAPY_PROXY'] = proxy
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=os.getcwd(), env=env)
        if result.returncode == 0:
            await update.message.reply_text('✅ Сбор данных завершён! Отправляю файл...', reply_markup=main_menu_keyboard)
            with open(output_file, 'rb') as f:
                await update.message.reply_document(document=InputFile(f, filename=output_file))
            os.remove(output_file)
        else:
            await update.message.reply_text('❌ Произошла ошибка при запуске Scrapy!', reply_markup=main_menu_keyboard)
            await update.message.reply_text(result.stderr, reply_markup=main_menu_keyboard)
    except Exception as e:
        await update.message.reply_text(f'Ошибка: {e}', reply_markup=main_menu_keyboard)

# --- Обработка текстовых кнопок главного меню ---
async def handle_menu_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text
    if text == '▶️ Запустить сбор данных':
        await run_scrapy(update, context)
    elif text == '⚙️ Настройки':
        await settings_command(update, context)
    elif text == '📄 Мои параметры':
        await my_params(update, context)
    elif text == 'ℹ️ О боте':
        await about(update, context)
    elif text == '⬅️ В главное меню':
        await main_menu(update, context)
    else:
        await update.message.reply_text('Пожалуйста, используйте кнопки меню.', reply_markup=main_menu_keyboard)

# --- Основная функция ---
async def main():
    init_db()
    app = ApplicationBuilder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler('start', start))
    app.add_handler(CommandHandler('menu', main_menu))
    app.add_handler(CommandHandler('about', about))
    app.add_handler(CommandHandler('myparams', my_params))
    app.add_handler(CommandHandler('run', run_scrapy))
    conv_handler = ConversationHandler(
        entry_points=[CommandHandler('settings', settings_command)],
        states={
            SELECT_PARAM: [CallbackQueryHandler(select_param)],
            INPUT_VALUE: [MessageHandler(filters.TEXT & ~filters.COMMAND, input_value)],
        },
        fallbacks=[MessageHandler(filters.Regex('⬅️ В главное меню'), main_menu)]
    )
    app.add_handler(conv_handler)
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_menu_buttons))
    await app.run_polling()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main()) 