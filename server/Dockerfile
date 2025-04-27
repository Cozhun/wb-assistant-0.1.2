# Используем актуальную версию Node.js
FROM node:18-alpine

# Создаем директорию приложения
WORKDIR /app

# Установка зависимостей
COPY package*.json ./
RUN npm ci --only=production

# Копирование исходного кода
COPY . .

# Создаем директорию для логов
RUN mkdir -p logs && chmod 777 logs

# Переменные окружения
ENV NODE_ENV=production
ENV PORT=3000
ENV CORS_ORIGIN="*"

# Экспонируем порт, на котором запускается приложение
EXPOSE 3000

# Установка healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/healthcheck || exit 1

# Запуск приложения
CMD ["node", "src/app.js"]

# Метаданные
LABEL maintainer="WB Assistant Team"
LABEL version="0.1.2"
LABEL description="API сервер для WB Assistant" 