import scrapy  # Импортируем модуль scrapy
from scrapy_project.items import ExampleItem  # Импортируем наш Item

# Определяем класс паука, наследуемый от scrapy.Spider
class ExampleSpider(scrapy.Spider):
    name = "example"  # Имя паука, используется для запуска
    allowed_domains = ["quotes.toscrape.com"]  # Разрешённые домены для обхода
    start_urls = ["http://quotes.toscrape.com/"]  # Список стартовых URL

    def parse(self, response):
        # Метод parse вызывается для обработки ответа на каждый URL
        for quote in response.css("div.quote"):
            item = ExampleItem()  # Создаём экземпляр Item
            # Извлекаем текст цитаты
            item["title"] = quote.css("span.text::text").get()
            # Сохраняем URL страницы
            item["url"] = response.url
            yield item  # Возвращаем результат 