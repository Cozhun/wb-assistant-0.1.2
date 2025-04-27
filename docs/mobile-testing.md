# Инструкция по тестированию мобильного приложения

## 1. Подготовка окружения на ноутбуке

### 1.1. Настройка сети
- Создать локальную Wi-Fi точку доступа на ноутбуке
  ```powershell
  # Windows PowerShell (от администратора)
  netsh wlan set hostednetwork mode=allow ssid="WB-Assistant" key="your-password"
  netsh wlan start hostednetwork
  ```
- Или использовать существующую Wi-Fi сеть (оба устройства должны быть в одной сети)

### 1.2. Настройка сервера
- В файле конфигурации сервера указать:
  ```typescript
  const config = {
    server: {
      host: '0.0.0.0',  // Важно для доступа извне
      port: 3000
    },
    // ... остальные настройки
  };
  ```
- Проверить, что брандмауэр Windows разрешает входящие подключения на порт сервера

### 1.3. Определение IP адреса
- Открыть командную строку и выполнить:
  ```powershell
  ipconfig
  ```
- Найти IPv4-адрес в используемой сети (обычно начинается с 192.168.x.x)

## 2. Настройка окружения для разработки

### 2.1. Требования к системе
- Flutter SDK 3.16.x или выше 
- Dart SDK 3.x или выше
- JDK 11 или выше
- Android Studio:
  - Android SDK Platform 33
  - Android SDK Build-Tools 33
  - Intel x86 Atom_64 System Image или Google APIs Intel x86 Atom System Image
- Переменные окружения:
  ```powershell
  # Windows
  setx ANDROID_HOME "%LOCALAPPDATA%\Android\Sdk"
  setx PATH "%PATH%;%LOCALAPPDATA%\Android\Sdk\platform-tools"
  setx PATH "%PATH%;путь_к_flutter\bin"
  ```

### 2.2. Настройка Android Studio
- Установить плагин Flutter
- Установить плагин Dart
- Настроить эмулятор Android

### 2.3. Настройка Flutter SDK
```bash
flutter doctor
flutter doctor --android-licenses
flutter pub get
```

## 3. Варианты тестирования

### 3.1. Физическое устройство (основной вариант)
1. Включить режим разработчика на Android:
   - Настройки -> О телефоне -> Номер сборки (нажать 7 раз)
   - Настройки -> Параметры разработчика -> Отладка по USB
2. Подключить устройство через USB
3. Разрешить отладку на устройстве
4. Проверить подключение:
   ```bash
   adb devices
   ```
5. Запустить приложение:
   ```bash
   cd mobile-client
   npm run android
   ```

### 3.2. Эмулятор (для разработки)
1. Запустить эмулятор через Android Studio:
   - Tools -> Device Manager -> Play
2. Или через командную строку:
   ```bash
   emulator -avd Pixel_6_Pro_API_33
   ```
3. Запустить приложение:
   ```bash
   cd mobile-client
   npm run android
   ```

## 4. Отладка

### 4.1. Логирование
- Просмотр логов:
  ```bash
  adb logcat *:S ReactNative:V ReactNativeJS:V
  ```
- Очистка логов:
  ```bash
  adb logcat -c
  ```

### 4.2. React Native Debugger
1. Установить React Native Debugger
2. Запустить отладчик
3. В приложении: Shake устройство -> Debug
4. Порт по умолчанию: 8081

## 5. Возможные проблемы и решения

### 5.1. Сетевые проблемы
- **Проблема**: Приложение не может подключиться к серверу
  - Проверить adb reverse:
    ```bash
    adb reverse tcp:3000 tcp:3000
    ```
  - Проверить брандмауэр Windows
  - Проверить настройки сети устройства

- **Проблема**: CORS ошибки
  ```typescript
  // server/src/index.ts
  app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
  }));
  ```

### 5.2. Проблемы сборки
- Очистка кэша:
  ```bash
  cd android
  ./gradlew clean
  cd ..
  npm start -- --reset-cache
  ```
- Проверка зависимостей:
  ```bash
  cd android
  ./gradlew app:dependencies
  ```

### 5.3. Проблемы с устройствами
- **Сканер**: 
  - Проверить разрешения в AndroidManifest.xml
  - Проверить runtime permissions
- **Принтер**: 
  - Проверить поддержку Bluetooth
  - Проверить драйверы принтера

## 6. Рекомендации по демонстрации

### 6.1. Подготовка
- Собрать release-версию приложения:
  ```bash
  cd android
  ./gradlew assembleRelease
  ```
- Подготовить тестовые данные
- Проверить все функции
- Настроить сеть заранее

### 6.2. Сценарий демонстрации
1. Показать веб-интерфейс на ноутбуке
2. Продемонстрировать создание задания
3. Показать получение задания на мобильном
4. Продемонстрировать процесс сборки
5. Показать синхронизацию статусов

### 6.3. Что иметь при себе
- USB кабель (для отладки)
- Тестовый принтер (если требуется)
- Резервный мобильный хотспот
- APK файл приложения
- Предварительно загруженные тестовые данные 