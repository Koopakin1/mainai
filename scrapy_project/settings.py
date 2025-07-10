# Файл настроек Scrapy

BOT_NAME = "scrapy_project"  # Имя бота Scrapy

SPIDER_MODULES = ["scrapy_project.spiders"]  # Где искать пауков
NEWSPIDER_MODULE = "scrapy_project.spiders"  # Где создавать новых пауков

# Соблюдать правила robots.txt
ROBOTSTXT_OBEY = True

# Задержка между запросами (по умолчанию 1 секунда)
DOWNLOAD_DELAY = 1

# Максимальное количество одновременных запросов
CONCURRENT_REQUESTS = 8

# Прочие настройки можно добавить по мере необходимости 