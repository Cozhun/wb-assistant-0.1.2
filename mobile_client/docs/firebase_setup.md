# Настройка Firebase для push-уведомлений

Этот документ содержит инструкции по настройке Firebase Cloud Messaging (FCM) для отправки push-уведомлений в мобильном приложении WB Assistant.

## Предварительные требования

1. Учетная запись Google
2. Проект в Firebase Console (создайте его на [console.firebase.google.com](https://console.firebase.google.com))
3. Flutter SDK установлен
4. Приложение WB Assistant настроено для Android и/или iOS

## Шаги настройки

### 1. Создание проекта Firebase

1. Перейдите на [console.firebase.google.com](https://console.firebase.google.com)
2. Нажмите "Создать проект"
3. Введите название проекта (например, "WB Assistant")
4. Следуйте инструкциям по настройке проекта
5. После создания проекта перейдите на его панель управления

### 2. Регистрация приложения Android

1. В консоли Firebase нажмите на иконку Android, чтобы добавить приложение
2. Введите имя пакета из `android/app/build.gradle` (обычно это `com.yourcompany.wb_assistant`)
3. Введите название приложения и nickname (опционально)
4. Скачайте файл `google-services.json`
5. Поместите файл в директорию `android/app/`
6. Следуйте инструкциям Firebase по обновлению файлов gradle:

   В `android/build.gradle` добавьте:
   ```groovy
   buildscript {
     dependencies {
       // Другие зависимости...
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }
   ```

   В `android/app/build.gradle` добавьте в конец файла:
   ```groovy
   apply plugin: 'com.google.gms.google-services'
   ```

### 3. Регистрация приложения iOS (если требуется)

1. В консоли Firebase нажмите на иконку iOS, чтобы добавить приложение
2. Введите Bundle ID (обычно это `com.yourcompany.wbAssistant`)
3. Скачайте файл `GoogleService-Info.plist`
4. Откройте проект в Xcode и добавьте файл в корневую папку проекта (убедитесь, что опция "Copy items if needed" отмечена)
5. Настройте возможности для push-уведомлений в Xcode:
   - В Target -> Capabilities включите Push Notifications
   - Включите Background Modes и отметьте "Remote notifications"

### 4. Настройка Firebase Messaging в Flutter

1. Убедитесь, что в `pubspec.yaml` добавлены необходимые зависимости:
   ```yaml
   dependencies:
     firebase_core: ^2.27.1
     firebase_messaging: ^14.7.30
     flutter_local_notifications: ^16.4.2
   ```

2. Запустите `flutter pub get` для установки зависимостей

3. Настройте инициализацию Firebase в `main.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'package:firebase_messaging/firebase_messaging.dart';
   import 'app/services/notification_service.dart';

   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Обработка сообщения в фоновом режиме
     print("Handling a background message: ${message.messageId}");
   }

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Инициализация Firebase
     await Firebase.initializeApp();
     
     // Обработчик фоновых сообщений
     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
     
     // Инициализация сервиса уведомлений
     await NotificationService.initialize();
     
     runApp(const MyApp());
   }
   ```

### 5. Тестирование уведомлений

После настройки можно протестировать отправку уведомлений через Firebase Console:

1. В Firebase Console перейдите в раздел "Cloud Messaging"
2. Нажмите "Создать первую кампанию" -> "Уведомление"
3. Заполните заголовок и текст уведомления
4. В разделе "Target" выберите ваше приложение
5. Настройте остальные параметры и отправьте тестовое уведомление

## Отправка уведомлений через API

Для отправки уведомлений программно (с вашего сервера) используйте Firebase Admin SDK или HTTP API:

### Пример с использованием HTTP API

```javascript
const axios = require('axios');

const sendNotification = async (token, title, body, data) => {
  const message = {
    to: token,
    notification: {
      title,
      body,
    },
    data,
  };

  try {
    const response = await axios.post(
      'https://fcm.googleapis.com/fcm/send',
      message,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=YOUR_SERVER_KEY_FROM_FIREBASE_CONSOLE`,
        },
      }
    );
    console.log('Notification sent successfully:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
};
```

## Дополнительная информация

- [Документация Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Плагин firebase_messaging для Flutter](https://pub.dev/packages/firebase_messaging)
- [Руководство по Flutter и FCM](https://firebase.flutter.dev/docs/messaging/overview/)

## Решение проблем

### Уведомления не отображаются

1. Убедитесь, что приложение имеет разрешение на показ уведомлений
2. Проверьте логи на наличие ошибок
3. Удостоверьтесь, что FCM токен корректно зарегистрирован на сервере

### Проблемы с iOS

1. Убедитесь, что настроены APNS сертификаты в Firebase
2. Проверьте, что включены возможности Push Notifications и Background Modes в Xcode
3. Тестируйте на реальном устройстве (симуляторы не поддерживают push-уведомления)

### Проблемы с Android

1. Убедитесь, что файл `google-services.json` правильно размещен
2. Проверьте, что в манифесте добавлены необходимые разрешения
3. Убедитесь, что устройство/эмулятор имеет Google Play Services 