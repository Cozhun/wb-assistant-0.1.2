# Скрипт для запуска локальной тестовой среды
Write-Host "Запуск локальной тестовой среды..."

# Получаем IP-адрес компьютера в локальной сети
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
if (-not $ipAddress) {
    # Если Wi-Fi не найден, пробуем Ethernet
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress
}

if (-not $ipAddress) {
    # Если ни один из интерфейсов не найден, используем localhost
    $ipAddress = "127.0.0.1"
    Write-Host "Не удалось определить IP-адрес в локальной сети. Используется localhost."
} else {
    Write-Host "IP-адрес в локальной сети: $ipAddress"
}

# Обновляем конфигурацию API в мобильном клиенте
$apiServicePath = "../mobile_client/lib/app/services/api_service.dart"
$apiServiceContent = Get-Content -Path $apiServicePath -Raw
$updatedContent = $apiServiceContent -replace "return 'http://192.168.1.100:3000';", "return 'http://$ipAddress`:3000';"
Set-Content -Path $apiServicePath -Value $updatedContent

Write-Host "Конфигурация API обновлена с IP-адресом: $ipAddress"

# Проверяем наличие директории для изображений
$imagesDir = "../mobile_client/assets/images"
if (-not (Test-Path $imagesDir)) {
    Write-Host "Создание директории для изображений..."
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
    Write-Host "Директория создана: $imagesDir"
}

# Запускаем Docker-контейнеры
Write-Host "Запуск Docker-контейнеров..."
cd ..
docker-compose up -d

# Проверяем, что контейнеры запущены
Start-Sleep -Seconds 5
$containers = docker ps --format "{{.Names}}"
Write-Host "Запущенные контейнеры:"
Write-Host $containers

# Выводим информацию о доступе
Write-Host "Система готова к тестированию в локальной сети!"
Write-Host "Веб-клиент доступен по адресу: http://$ipAddress"
Write-Host "API доступно по адресу: http://$ipAddress`:3000/api"
Write-Host "Для тестирования мобильного приложения используйте IP: $ipAddress"

Write-Host "Для запуска мобильного приложения выполните:"
Write-Host "cd ../mobile_client"
Write-Host "flutter run"

Write-Host "Для остановки контейнеров выполните:"
Write-Host "docker-compose down" 