Write-Host "Starting migrations..."

# Check if postgres container is running
$container = docker ps --filter "name=wb-assistant-012-postgres-1" --format "{{.Names}}"
if (-not $container) {
    Write-Host "Starting postgres container..."
    cd ..
    docker-compose up -d postgres
    Start-Sleep -Seconds 5
} else {
    cd ..
}

# Create migrations table
Write-Host "Creating migrations table..."
docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);"

# Run all migration files in order
$migrationFiles = Get-ChildItem -Path "server/src/models/migrations" -Filter "*.sql" | Sort-Object Name
foreach ($file in $migrationFiles) {
    $fileName = $file.Name
    Write-Host "Running migration: $fileName"
    
    # Get file content and execute
    $content = Get-Content -Path "server/src/models/migrations/$fileName" -Raw
    docker exec -i wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "$content"
    
    # Record migration
    docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "
    INSERT INTO migrations (name) 
    SELECT '$fileName' 
    WHERE NOT EXISTS (SELECT 1 FROM migrations WHERE name = '$fileName');"
}

# Check tables
Write-Host "Checking tables after migrations..."
docker exec wb-assistant-012-postgres-1 psql -U postgres -d wb_assistant -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

Write-Host "Migrations completed!" 