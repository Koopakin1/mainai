import scrapy  # Импортируем модуль scrapy

# Определяем класс для хранения данных, которые будет собирать паук
class ExampleItem(scrapy.Item):
    # Заголовок страницы
    title = scrapy.Field()
    # URL страницы
    url = scrapy.Field() 