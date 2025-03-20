# Скрипт для пересборки и перезапуска контейнера сервера
Write-Host "Пересборка и перезапуск сервера..." -ForegroundColor Green

# Переходим в корневую директорию проекта
cd ..

# Остановка контейнера сервера
Write-Host "Остановка контейнера сервера..." -ForegroundColor Yellow
docker stop wb-assistant-012-server-1

# Удаление контейнера сервера
Write-Host "Удаление контейнера сервера..." -ForegroundColor Yellow
docker rm wb-assistant-012-server-1

# Пересборка образа сервера
Write-Host "Пересборка образа сервера..." -ForegroundColor Yellow
docker-compose build server

# Запуск контейнера сервера
Write-Host "Запуск контейнера сервера..." -ForegroundColor Yellow
docker-compose up -d server

# Ожидание запуска
Write-Host "Ожидание запуска сервера..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Проверка статуса
Write-Host "Проверка статуса сервера..." -ForegroundColor Yellow
docker ps --filter "name=wb-assistant-012-server-1"

# Проверка логов
Write-Host "Логи сервера:" -ForegroundColor Green
docker logs wb-assistant-012-server-1

Write-Host "Пересборка и перезапуск сервера завершены!" -ForegroundColor Green
Write-Host "Теперь миграции должны быть выполнены автоматически" -ForegroundColor Green 