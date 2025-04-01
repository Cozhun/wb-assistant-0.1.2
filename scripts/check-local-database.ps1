# Скрипт для проверки и настройки локальной базы данных PostgreSQL
Write-Host "Проверка локальной базы данных PostgreSQL..." -ForegroundColor Green

# Проверяем наличие контейнера PostgreSQL
$postgresContainer = docker ps --format "{{.Names}}" | Select-String "postgres"

if (-not $postgresContainer) {
    Write-Host "Контейнер PostgreSQL не запущен." -ForegroundColor Yellow
    
    # Проверяем наличие образа PostgreSQL
    $postgresImage = docker images postgres:14-alpine --format "{{.Repository}}"
    
    if (-not $postgresImage) {
        Write-Host "Загрузка образа PostgreSQL..." -ForegroundColor Yellow
        docker pull postgres:14-alpine
    }
    
    # Загружаем параметры из .env файла
    $envPath = "../.env"
    $envContent = Get-Content -Path $envPath -ErrorAction SilentlyContinue
    
    $dbUser = "postgres"
    $dbPassword = "postgres"
    $dbName = "wb_assistant"
    
    if ($envContent) {
        foreach ($line in $envContent) {
            if ($line -match "DB_USER=(.+)") {
                $dbUser = $Matches[1]
            }
            elseif ($line -match "DB_PASSWORD=(.+)") {
                $dbPassword = $Matches[1]
            }
            elseif ($line -match "DB_NAME=(.+)") {
                $dbName = $Matches[1]
            }
        }
    }
    
    # Запускаем контейнер PostgreSQL для локальной разработки
    Write-Host "Запуск контейнера PostgreSQL для локальной разработки..." -ForegroundColor Yellow
    
    docker run --name postgres-local -e POSTGRES_USER=$dbUser -e POSTGRES_PASSWORD=$dbPassword -e POSTGRES_DB=$dbName -p 5432:5432 -d postgres:14-alpine
    
    if ($?) {
        Write-Host "Контейнер PostgreSQL запущен успешно!" -ForegroundColor Green
        Write-Host "Ожидание инициализации базы данных..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Не удалось запустить контейнер PostgreSQL." -ForegroundColor Red
        Write-Host "Возможно, порт 5432 уже занят или у вас нет прав на запуск Docker." -ForegroundColor Red
        Write-Host "Проверьте настройки Docker и повторите попытку." -ForegroundColor Red
        Exit 1
    }
} else {
    Write-Host "Контейнер PostgreSQL уже запущен: $postgresContainer" -ForegroundColor Green
}

# Проверяем соединение с базой данных
Write-Host "Проверка соединения с базой данных..." -ForegroundColor Yellow

$checkResult = docker exec postgres-local pg_isready -U postgres
if ($?) {
    Write-Host "Соединение с базой данных установлено успешно!" -ForegroundColor Green
    Write-Host "База данных PostgreSQL готова к использованию." -ForegroundColor Green
    Write-Host "Хост: localhost" -ForegroundColor Green
    Write-Host "Порт: 5432" -ForegroundColor Green
    Write-Host "Пользователь: postgres" -ForegroundColor Green
    Write-Host "База данных: wb_assistant" -ForegroundColor Green
} else {
    Write-Host "Не удалось подключиться к базе данных." -ForegroundColor Red
    Write-Host "Проверьте настройки и повторите попытку." -ForegroundColor Red
    Exit 1
}

# Проверяем и обновляем .env файл для локальной разработки
$envPath = "../.env"
$envContent = Get-Content -Path $envPath -ErrorAction SilentlyContinue
$updatedContent = @()

$dbHostUpdated = $false

if ($envContent) {
    foreach ($line in $envContent) {
        if ($line -match "DB_HOST=") {
            $updatedContent += "DB_HOST=localhost"
            $dbHostUpdated = $true
        } else {
            $updatedContent += $line
        }
    }
} else {
    Write-Host "Файл .env не найден." -ForegroundColor Yellow
}

if ($dbHostUpdated) {
    Set-Content -Path $envPath -Value $updatedContent
    Write-Host "Файл .env обновлен для локальной разработки." -ForegroundColor Green
}

Write-Host "Настройка базы данных завершена успешно!" -ForegroundColor Green
Write-Host "Теперь вы можете запустить сервер с подключением к локальной базе данных." -ForegroundColor Green
Write-Host "Команда для запуска сервера: cd ../server && npm run dev" -ForegroundColor Cyan 