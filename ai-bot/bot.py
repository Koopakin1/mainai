import os
import logging
import requests
from telegram import (
    Update, ReplyKeyboardMarkup, KeyboardButton, InlineKeyboardMarkup, InlineKeyboardButton, ReplyKeyboardRemove
)
from telegram.ext import (
    ApplicationBuilder, CommandHandler, MessageHandler, ContextTypes, filters, CallbackQueryHandler, ConversationHandler
)

# Включаем логирование
logging.basicConfig(level=logging.INFO)

def get_secret(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return default

TELEGRAM_TOKEN = get_secret(os.environ.get('TELEGRAM_TOKEN_FILE', '/run/secrets/telegram_token'))
OPENAI_API_KEY = get_secret(os.environ.get('OPENAI_API_KEY_FILE', '/run/secrets/openai_api_key'))

# --- Константы для ConversationHandler ---
SELECT_SETTING, = range(1)

# --- Главное меню ---
main_menu = ReplyKeyboardMarkup([
    [KeyboardButton('📝 Сгенерировать')],
    [KeyboardButton('⚙️ Настройки генерации')],
    [KeyboardButton('ℹ️ О боте')]
], resize_keyboard=True)

# --- Настройки генерации ---
FORMAT_OPTIONS = [
    ('Заголовок + текст', 'title_text'),
    ('Только текст', 'text'),
    ('Только заголовок', 'title')
]
TONE_OPTIONS = [
    ('Нейтральная', 'neutral'),
    ('Позитивная', 'positive'),
    ('Продающая', 'sales'),
    ('Экспертная', 'expert')
]
LENGTH_OPTIONS = [
    ('Короткий', 'short'),
    ('Средний', 'medium'),
    ('Длинный', 'long')
]

# --- Команда /start ---
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        '👋 Привет! Я бот-генератор текста и заголовков с помощью ИИ.\n'
        'Выберите действие в меню.',
        reply_markup=main_menu
    )

# --- Главное меню ---
async def main_menu_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text('Главное меню:', reply_markup=main_menu)

# --- О боте ---
async def about(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        '🤖 <b>AI Telegram Bot</b>\n\n'
        'Генерирует тексты и заголовки с помощью ИИ (OpenAI).\n'
        'Вы можете выбрать формат, тональность и длину текста в настройках.',
        parse_mode='HTML',
        reply_markup=main_menu
    )

# --- Настройки генерации ---
async def settings_menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    keyboard = [
        [InlineKeyboardButton('Формат', callback_data='set_format')],
        [InlineKeyboardButton('Тональность', callback_data='set_tone')],
        [InlineKeyboardButton('Длина', callback_data='set_length')],
        [InlineKeyboardButton('⬅️ В главное меню', callback_data='back_to_menu')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text('Настройки генерации:', reply_markup=reply_markup)
    return SELECT_SETTING

async def settings_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    data = query.data
    if data == 'set_format':
        keyboard = [[InlineKeyboardButton(name, callback_data=f'format_{val}')] for name, val in FORMAT_OPTIONS]
        keyboard.append([InlineKeyboardButton('⬅️ Назад', callback_data='settings_menu')])
        await query.edit_message_text('Выберите формат генерации:', reply_markup=InlineKeyboardMarkup(keyboard))
    elif data == 'set_tone':
        keyboard = [[InlineKeyboardButton(name, callback_data=f'tone_{val}')] for name, val in TONE_OPTIONS]
        keyboard.append([InlineKeyboardButton('⬅️ Назад', callback_data='settings_menu')])
        await query.edit_message_text('Выберите тональность:', reply_markup=InlineKeyboardMarkup(keyboard))
    elif data == 'set_length':
        keyboard = [[InlineKeyboardButton(name, callback_data=f'length_{val}')] for name, val in LENGTH_OPTIONS]
        keyboard.append([InlineKeyboardButton('⬅️ Назад', callback_data='settings_menu')])
        await query.edit_message_text('Выберите длину текста:', reply_markup=InlineKeyboardMarkup(keyboard))
    elif data == 'settings_menu':
        await settings_menu(query, context)
    elif data == 'back_to_menu':
        await query.edit_message_text('Главное меню:')
        await main_menu_handler(query, context)
    elif data.startswith('format_'):
        context.user_data['format'] = data.replace('format_', '')
        await query.edit_message_text('Формат сохранён!')
        await settings_menu(query, context)
    elif data.startswith('tone_'):
        context.user_data['tone'] = data.replace('tone_', '')
        await query.edit_message_text('Тональность сохранена!')
        await settings_menu(query, context)
    elif data.startswith('length_'):
        context.user_data['length'] = data.replace('length_', '')
        await query.edit_message_text('Длина текста сохранена!')
        await settings_menu(query, context)
    return SELECT_SETTING

# --- Обработка текстовых сообщений ---
async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()
    if text == '📝 Сгенерировать':
        await update.message.reply_text('Пожалуйста, отправьте ваш запрос (например: "Описание для сайта про кофе")', reply_markup=ReplyKeyboardRemove())
        context.user_data['awaiting_prompt'] = True
        return
    if text == '⚙️ Настройки генерации':
        await settings_menu(update, context)
        return
    if text == 'ℹ️ О боте':
        await about(update, context)
        return
    if context.user_data.get('awaiting_prompt'):
        await update.message.reply_text('⏳ Генерирую ответ...')
        # Получаем настройки пользователя
        fmt = context.user_data.get('format', 'title_text')
        tone = context.user_data.get('tone', 'neutral')
        length = context.user_data.get('length', 'medium')
        title, body = generate_ai_text(text, fmt, tone, length)
        if fmt == 'title_text':
            await update.message.reply_text(f'<b>Заголовок:</b> {title}\n<b>Текст:</b> {body}', parse_mode='HTML', reply_markup=main_menu)
        elif fmt == 'title':
            await update.message.reply_text(f'<b>Заголовок:</b> {title}', parse_mode='HTML', reply_markup=main_menu)
        elif fmt == 'text':
            await update.message.reply_text(f'<b>Текст:</b> {body}', parse_mode='HTML', reply_markup=main_menu)
        context.user_data['awaiting_prompt'] = False
        return
    await update.message.reply_text('Пожалуйста, используйте кнопки меню.', reply_markup=main_menu)

# --- Генерация текста через OpenAI API ---
def generate_ai_text(prompt: str, fmt: str, tone: str, length: str):
    """
    Отправляет запрос к OpenAI API с учётом формата, тона и длины
    """
    url = 'https://api.openai.com/v1/chat/completions'
    headers = {
        'Authorization': f'Bearer {OPENAI_API_KEY}',
        'Content-Type': 'application/json'
    }
    # Формируем системный prompt с учётом настроек
    system_prompt = (
        f'Ты — помощник-копирайтер. Формат ответа: {fmt}. '
        f'Тональность: {tone}. Длина: {length}. '
        'Если выбран формат "Заголовок + текст", сначала сгенерируй короткий заголовок, затем абзац текста. '
        'Ответ возвращай в формате: "Заголовок: ...\nТекст: ...". '
        'Если только заголовок — только "Заголовок: ...". Если только текст — только "Текст: ...".'
    )
    data = {
        'model': 'gpt-3.5-turbo',
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 400,
        'temperature': 0.8
    }
    try:
        resp = requests.post(url, headers=headers, json=data, timeout=30)
        resp.raise_for_status()
        answer = resp.json()['choices'][0]['message']['content']
        # Парсим ответ
        title, body = '', ''
        if 'Заголовок:' in answer:
            title = answer.split('Заголовок:')[1].split('Текст:')[0].strip() if 'Текст:' in answer else answer.split('Заголовок:')[1].strip()
        if 'Текст:' in answer:
            body = answer.split('Текст:')[1].strip()
        return title, body
    except Exception as e:
        logging.error(f'Ошибка OpenAI: {e}')
        return 'Ошибка генерации', 'Не удалось получить ответ от ИИ.'

# --- Основная функция ---
async def main():
    app = ApplicationBuilder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler('start', start))
    app.add_handler(CommandHandler('menu', main_menu_handler))
    app.add_handler(CommandHandler('about', about))
    conv_handler = ConversationHandler(
        entry_points=[CommandHandler('settings', settings_menu)],
        states={
            SELECT_SETTING: [CallbackQueryHandler(settings_callback)]
        },
        fallbacks=[CommandHandler('menu', main_menu_handler)]
    )
    app.add_handler(conv_handler)
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    await app.run_polling()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main()) 