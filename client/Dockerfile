# Этап разработки
FROM node:20-alpine as build

WORKDIR /app

# Копируем файлы зависимостей
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем исходный код
COPY . .

# Собираем приложение
RUN npm run build

# Этап production
FROM node:20-alpine

WORKDIR /app

# Устанавливаем serve для раздачи статики
RUN npm install -g serve

# Копируем собранное приложение
COPY --from=build /app/dist ./dist

EXPOSE 80

CMD ["serve", "-s", "dist", "-l", "80"] 