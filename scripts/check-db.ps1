# Скрипт для проверки базы данных PostgreSQL
$outputFile = "../db-check-result.txt"

# Проверяем версию PostgreSQL
Write-Host "Проверка версии PostgreSQL..." -ForegroundColor Green
docker exec -it wb-assistant-012-postgres-1 psql -U postgres -c "SELECT version() as postgres_version" | Out-File -FilePath $outputFile -Append

# Проверяем список баз данных
Write-Host "Проверка списка баз данных..." -ForegroundColor Green
docker exec -it wb-assistant-012-postgres-1 psql -U postgres -c "SELECT datname FROM pg_database" | Out-File -FilePath $outputFile -Append

# Проверяем список таблиц в базе данных wb_assistant
Write-Host "Проверка таблиц в базе данных wb_assistant..." -ForegroundColor Green
docker exec -it wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'" | Out-File -FilePath $outputFile -Append

# Выводим результат
Write-Host "Проверка завершена. Результаты сохранены в $outputFile" -ForegroundColor Green 