# Скрипт для остановки всех ботов в Docker
# Запуск: .\stop-bots.ps1

Write-Host "🛑 Остановка всех ботов..." -ForegroundColor Yellow

# Остановка и удаление контейнеров
docker-compose down

Write-Host "✅ Все контейнеры остановлены и удалены" -ForegroundColor Green

# Спрашиваем о полной очистке
$cleanup = Read-Host "Удалить также Docker образы? (y/n)"

if ($cleanup -eq "y" -or $cleanup -eq "Y") {
    Write-Host "🗑️  Удаление Docker образов..." -ForegroundColor Yellow
    docker-compose down --rmi all
    Write-Host "✅ Образы удалены" -ForegroundColor Green
}

Write-Host "`n📋 Статус Docker контейнеров:" -ForegroundColor Cyan
docker ps -a

Write-Host "`n🎉 Очистка завершена!" -ForegroundColor Green 