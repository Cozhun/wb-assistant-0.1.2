# Скрипт для запуска миграций вручную
Write-Host "Запуск миграций вручную..." -ForegroundColor Green

# Переходим в корневую директорию проекта
cd ..

# Проверяем, что контейнер PostgreSQL запущен
$postgresContainer = docker ps --filter "name=wb-assistant-012-postgres-1" --format "{{.Names}}"

if (-not $postgresContainer) {
    Write-Host "Контейнер PostgreSQL не запущен. Запускаем контейнеры..." -ForegroundColor Red
    docker-compose up -d postgres
    Start-Sleep -Seconds 5
}

# Копируем файлы миграций в контейнер PostgreSQL
Write-Host "Копирование файлов миграций в контейнер PostgreSQL..." -ForegroundColor Yellow
$migrationsDir = "server/src/models/migrations"
$targetDir = "/tmp/migrations"

# Создаем временную директорию в контейнере
docker exec wb-assistant-012-postgres-1 mkdir -p $targetDir

# Копируем каждый файл миграции в контейнер
$migrationFiles = Get-ChildItem -Path $migrationsDir -Filter "*.sql"
foreach ($file in $migrationFiles) {
    $sourceFile = "$migrationsDir/$($file.Name)"
    $targetFile = "$targetDir/$($file.Name)"
    Get-Content $sourceFile | docker exec -i wb-assistant-012-postgres-1 sh -c "cat > $targetFile"
    Write-Host "Скопирован файл: $($file.Name)" -ForegroundColor Yellow
}

# Создаем таблицу миграций, если она не существует
Write-Host "Создание таблицы миграций..." -ForegroundColor Yellow
docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);"

# Получаем список выполненных миграций
Write-Host "Получение списка выполненных миграций..." -ForegroundColor Yellow
$executedMigrations = docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -t -c "SELECT name FROM migrations;"

# Выполняем каждую миграцию
foreach ($file in ($migrationFiles | Sort-Object Name)) {
    $fileName = $file.Name
    
    # Проверяем, была ли миграция уже выполнена
    $migrationExecuted = $executedMigrations -match $fileName
    
    if (-not $migrationExecuted) {
        Write-Host "Выполнение миграции: $fileName" -ForegroundColor Green
        
        # Запускаем SQL-скрипт
        docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -f "/tmp/migrations/$fileName"
        
        # Записываем информацию о выполненной миграции
        docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "INSERT INTO migrations (name) VALUES ('$fileName');"
        
        Write-Host "Миграция $fileName выполнена успешно" -ForegroundColor Green
    } else {
        Write-Host "Миграция $fileName уже выполнена ранее" -ForegroundColor Yellow
    }
}

# Проверяем список таблиц после миграций
Write-Host "Проверка списка таблиц после миграций..." -ForegroundColor Green
docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

Write-Host "Миграции успешно выполнены!" -ForegroundColor Green 