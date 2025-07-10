import logging
from telegram import Update, ReplyKeyboardMarkup, KeyboardButton
from telegram.ext import ApplicationBuilder, CommandHandler, MessageHandler, ContextTypes, filters
from kafka import KafkaAdminClient, KafkaProducer, KafkaConsumer
from kafka.admin import NewTopic
import os

def get_secret(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return default

TELEGRAM_TOKEN = get_secret(os.environ.get('TELEGRAM_TOKEN_FILE', '/run/secrets/telegram_token'))

# Логирование
logging.basicConfig(level=logging.INFO)

# Конфиг Kafka
KAFKA_BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')

# Главное меню
main_menu = ReplyKeyboardMarkup([
    [KeyboardButton('📋 Список топиков')],
    [KeyboardButton('➕ Создать топик'), KeyboardButton('➖ Удалить топик')],
    [KeyboardButton('👁️‍🗨️ Просмотреть сообщения'), KeyboardButton('✉️ Отправить сообщение')],
], resize_keyboard=True)

# Команда /start
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        '👋 Привет! Я бот для управления Kafka.\nВыберите действие:',
        reply_markup=main_menu
    )

# Обработка кнопок меню
async def handle_menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text
    if text == '📋 Список топиков':
        await list_topics(update)
    elif text == '➕ Создать топик':
        await update.message.reply_text('Введите имя нового топика:')
        context.user_data['action'] = 'create_topic'
    elif text == '➖ Удалить топик':
        await update.message.reply_text('Введите имя топика для удаления:')
        context.user_data['action'] = 'delete_topic'
    elif text == '👁️‍🗨️ Просмотреть сообщения':
        await update.message.reply_text('Введите имя топика для просмотра сообщений:')
        context.user_data['action'] = 'view_messages'
    elif text == '✉️ Отправить сообщение':
        await update.message.reply_text('Введите имя топика для отправки сообщения:')
        context.user_data['action'] = 'send_message_topic'
    else:
        # Обработка ввода для действий
        action = context.user_data.get('action')
        if action == 'create_topic':
            await create_topic(update, text)
            context.user_data['action'] = None
        elif action == 'delete_topic':
            await delete_topic(update, text)
            context.user_data['action'] = None
        elif action == 'view_messages':
            await view_messages(update, text)
            context.user_data['action'] = None
        elif action == 'send_message_topic':
            context.user_data['send_topic'] = text
            await update.message.reply_text('Введите текст сообщения:')
            context.user_data['action'] = 'send_message_text'
        elif action == 'send_message_text':
            topic = context.user_data.get('send_topic')
            await send_message(update, topic, text)
            context.user_data['action'] = None
            context.user_data['send_topic'] = None
        else:
            await update.message.reply_text('Пожалуйста, используйте кнопки меню.', reply_markup=main_menu)

# Список топиков
async def list_topics(update: Update):
    admin = KafkaAdminClient(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)
    topics = admin.list_topics()
    await update.message.reply_text('Топики Kafka:\n' + '\n'.join(topics), reply_markup=main_menu)
    admin.close()

# Создать топик
async def create_topic(update: Update, topic_name: str):
    admin = KafkaAdminClient(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)
    try:
        admin.create_topics([NewTopic(name=topic_name, num_partitions=1, replication_factor=1)])
        await update.message.reply_text(f'Топик "{topic_name}" создан.', reply_markup=main_menu)
    except Exception as e:
        await update.message.reply_text(f'Ошибка: {e}', reply_markup=main_menu)
    admin.close()

# Удалить топик
async def delete_topic(update: Update, topic_name: str):
    admin = KafkaAdminClient(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)
    try:
        admin.delete_topics([topic_name])
        await update.message.reply_text(f'Топик "{topic_name}" удалён.', reply_markup=main_menu)
    except Exception as e:
        await update.message.reply_text(f'Ошибка: {e}', reply_markup=main_menu)
    admin.close()

# Просмотреть сообщения
async def view_messages(update: Update, topic_name: str):
    try:
        consumer = KafkaConsumer(topic_name, bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS, auto_offset_reset='earliest', consumer_timeout_ms=2000)
        messages = [msg.value.decode('utf-8') for msg in consumer]
        if messages:
            await update.message.reply_text('Сообщения:\n' + '\n'.join(messages[-10:]), reply_markup=main_menu)
        else:
            await update.message.reply_text('Нет сообщений в топике.', reply_markup=main_menu)
        consumer.close()
    except Exception as e:
        await update.message.reply_text(f'Ошибка: {e}', reply_markup=main_menu)

# Отправить сообщение
async def send_message(update: Update, topic_name: str, text: str):
    try:
        producer = KafkaProducer(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)
        producer.send(topic_name, text.encode('utf-8'))
        producer.flush()
        await update.message.reply_text(f'Сообщение отправлено в "{topic_name}".', reply_markup=main_menu)
    except Exception as e:
        await update.message.reply_text(f'Ошибка: {e}', reply_markup=main_menu)

# Основная функция
async def main():
    app = ApplicationBuilder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler('start', start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_menu))
    await app.run_polling()

if __name__ == '__main__':
    import asyncio
    asyncio.run(main()) 