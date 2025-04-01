#!/bin/bash

# Скрипт для резервного копирования базы данных WB Assistant

# Подгрузка переменных окружения
source ../.env.prod

# Настройки
BACKUP_DIR="/home/admin/backups/wb-assistant"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_BACKUP_PATH="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"

# Создаем директорию для бэкапов, если ее нет
mkdir -p $BACKUP_DIR

echo "Начинаем резервное копирование базы данных..."

# Выполняем дамп базы данных и сжимаем его
docker exec wb-postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > $DB_BACKUP_PATH

# Проверка успешности выполнения 
if [ $? -eq 0 ]; then
    echo "Резервное копирование завершено успешно: $DB_BACKUP_PATH"
    
    # Удаляем бэкапы старше 7 дней
    find $BACKUP_DIR -name "db_*.sql.gz" -type f -mtime +7 -delete
    
    # Если Duplicati настроен, можно добавить специальные действия или
    # просто использовать директорию бэкапов как источник данных для Duplicati
    
    exit 0
else
    echo "Ошибка при выполнении резервного копирования"
    exit 1
fi 