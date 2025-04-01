# Нативные функции и интеграции

## Обзор

В данном документе описаны подходы к интеграции нативных функций в кросс-платформенное Flutter-приложение WB Assistant, с особым вниманием к сканированию штрих-кодов, работе с камерой, push-уведомлениям и другим платформенно-зависимым функциям.

## Сканирование штрих-кодов

### Выбор решения для сканирования (CL: 90%)

Для реализации функциональности сканирования штрих-кодов, особенно критичной для складских операций, рекомендуется использовать пакет `flutter_barcode_scanner`.

```dart
// utils/barcode_scanner.dart
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BarcodeScanner {
  // Реализация для мобильных устройств
  static Future<String?> scanBarcode(BuildContext context) async {
    if (kIsWeb) {
      // Веб-версия - показываем диалог ручного ввода
      return _showWebInputDialog(context);
    }
    
    try {
      // Мобильная версия - используем нативное сканирование
      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666', // цвет линии сканирования
        'Отмена',  // текст кнопки отмены
        true,      // показывать вспышку
        ScanMode.BARCODE // режим сканирования
      );
      
      // Обработка результата
      if (barcodeScanRes == '-1') {
        // Пользователь отменил сканирование
        return null;
      }
      
      return barcodeScanRes;
    } catch (e) {
      // Обработка ошибок
      _showErrorDialog(context, 'Ошибка сканирования: $e');
      return null;
    }
  }
  
  // Диалог ручного ввода для веб-версии
  static Future<String?> _showWebInputDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ввод штрих-кода'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Введите штрих-код вручную',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );
  }
  
  // Показать диалог ошибки
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ошибка'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
```

**Обоснование**: `flutter_barcode_scanner` обеспечивает интеграцию с нативными API сканирования на Android и iOS, предлагая хорошую производительность и надежность. Для веб-версии предоставляется альтернативный интерфейс ручного ввода.

**Источники**:
- [flutter_barcode_scanner на pub.dev](https://pub.dev/packages/flutter_barcode_scanner)
- [Mobile Vision API (Android)](https://developers.google.com/vision)
- [AVCaptureMetadataOutput (iOS)](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput)

## Push-уведомления

### Реализация push-уведомлений (CL: 85%)

Для обеспечения своевременного информирования пользователей о новых задачах и событиях, рекомендуется использовать Firebase Cloud Messaging (FCM).

```dart
// services/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Веб не поддерживает некоторые функции уведомлений
      await _initializeWeb();
    } else {
      // Инициализация для мобильных устройств
      await _initializeMobile();
    }
    
    // Обработка полученных уведомлений
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Обработка нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  // Инициализация для веб
  static Future<void> _initializeWeb() async {
    // Запрос разрешения на веб-уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Получение токена для веб
    String? token = await _messaging.getToken(
      vapidKey: 'your-vapid-key',
    );
    
    if (token != null) {
      await _saveToken(token);
    }
  }
  
  // Инициализация для мобильных устройств
  static Future<void> _initializeMobile() async {
    // Запрос разрешения на уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    // Инициализация локальных уведомлений
    const AndroidInitializationSettings androidInitialize = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const IOSInitializationSettings iosInitialize = 
        IOSInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);
    
    await _localNotifications.initialize(
      initSettings,
      onSelectNotification: (payload) => _handleLocalNotificationTap(payload),
    );
    
    // Получение токена для мобильных устройств
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
    
    // Слушатель обновления токена
    _messaging.onTokenRefresh.listen(_saveToken);
  }
  
  // Обработка сообщения в активном приложении
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Показ локального уведомления для мобильных устройств
    if (!kIsWeb) {
      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
            'high_importance_channel',
            'Важные уведомления',
            importance: Importance.high,
            priority: Priority.high,
          );
      const NotificationDetails platformDetails = 
          NotificationDetails(android: androidDetails);
      
      await _localNotifications.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        platformDetails,
        payload: message.data['payload'],
      );
    }
    
    // Обработка данных уведомления
    _processNotificationData(message.data);
  }
  
  // Обработка нажатия на уведомление (Firebase)
  static void _handleNotificationTap(RemoteMessage message) {
    _processNotificationData(message.data);
  }
  
  // Обработка нажатия на локальное уведомление
  static void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      // Обработка данных уведомления
    }
  }
  
  // Обработка данных уведомления
  static void _processNotificationData(Map<String, dynamic> data) {
    // Логика навигации в зависимости от типа уведомления
    if (data.containsKey('type')) {
      final type = data['type'];
      
      if (type == 'new_task') {
        // Навигация к экрану задач
      } else if (type == 'order_status') {
        // Навигация к экрану заказа
      }
    }
  }
  
  // Сохранение токена в базу данных
  static Future<void> _saveToken(String token) async {
    // Сохранение токена в профиль пользователя
    // (API-запрос к серверу)
  }
  
  // Отправка пользовательских данных на сервер
  static Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.subscribeToTopic(topic);
    }
  }
  
  // Отписка от тематических уведомлений
  static Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
```

**Обоснование**: Firebase Cloud Messaging предоставляет надежную кросс-платформенную инфраструктуру для push-уведомлений, с поддержкой как Android/iOS, так и веб-приложений.

**Источники**:
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [firebase_messaging на pub.dev](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications на pub.dev](https://pub.dev/packages/flutter_local_notifications)

## Работа с камерой

### Интеграция с камерой (CL: 80%)

Для реализации функциональности фотографирования товаров и сканирования документов рекомендуется использовать пакет `camera`.

```dart
// services/camera_service.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  static CameraController? _controller;
  
  // Инициализация камеры
  static Future<bool> initialize() async {
    if (kIsWeb) {
      // Веб не поддерживает прямой доступ к камере через camera пакет
      return true;
    }
    
    try {
      _cameras = await availableCameras();
      return _cameras?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Получение фотографии с камеры
  static Future<File?> takePicture(BuildContext context) async {
    if (kIsWeb) {
      // Для веб используем image_picker
      return _pickImageWeb();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      await initialize();
      if (_cameras == null || _cameras!.isEmpty) {
        return null;
      }
    }
    
    return await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (context) => CameraScreen(cameras: _cameras!),
      ),
    );
  }
  
  // Для веб-версии используем image_picker
  static Future<File?> _pickImageWeb() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      return File(image.path);
    }
    
    return null;
  }
}

// Экран камеры для мобильных устройств
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const CameraScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);
  
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Обработка ошибки инициализации
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _takePicture() async {
    if (!_isInitialized || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final XFile image = await _controller.takePicture();
      final File imageFile = File(image.path);
      
      Navigator.of(context).pop(imageFile);
    } catch (e) {
      // Обработка ошибки съемки
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сделать фото'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          if (_isProcessing)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
```

**Обоснование**: Пакет `camera` обеспечивает доступ к нативным API камеры на мобильных устройствах, предоставляя высокую производительность и контроль над процессом съемки. Для веб-версии используется `image_picker`, предлагающий стандартный интерфейс браузера для выбора изображений.

**Источники**:
- [camera на pub.dev](https://pub.dev/packages/camera)
- [image_picker на pub.dev](https://pub.dev/packages/image_picker)

## Хранение данных

### Многоуровневая стратегия хранения (CL: 85%)

Для эффективного хранения данных в кросс-платформенном приложении рекомендуется использовать многоуровневый подход.

```dart
// services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class StorageService {
  /// Инициализация хранилища
  Future<void> initialize();
  
  /// Сохранение данных
  Future<void> saveData(String key, dynamic value);
  
  /// Получение данных
  Future<dynamic> getData(String key);
  
  /// Удаление данных
  Future<void> removeData(String key);
  
  /// Очистка всех данных
  Future<void> clear();
  
  /// Сохранение конфиденциальных данных
  Future<void> saveSecureData(String key, String value);
  
  /// Получение конфиденциальных данных
  Future<String?> getSecureData(String key);
  
  /// Удаление конфиденциальных данных
  Future<void> removeSecureData(String key);
}

class WebStorageService implements StorageService {
  late SharedPreferences _prefs;
  final Map<String, String> _secureStorage = {};
  
  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  @override
  Future<void> saveData(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      await _prefs.setString(key, jsonEncode(value));
    }
  }
  
  @override
  Future<dynamic> getData(String key) async {
    return _prefs.get(key);
  }
  
  @override
  Future<void> removeData(String key) async {
    await _prefs.remove(key);
  }
  
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
  
  @override
  Future<void> saveSecureData(String key, String value) async {
    // Простая имитация безопасного хранилища для веб
    // На самом деле не является безопасным!
    _secureStorage[key] = value;
  }
  
  @override
  Future<String?> getSecureData(String key) async {
    return _secureStorage[key];
  }
  
  @override
  Future<void> removeSecureData(String key) async {
    _secureStorage.remove(key);
  }
}

class MobileStorageService implements StorageService {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
  }
  
  @override
  Future<void> saveData(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      await _prefs.setString(key, jsonEncode(value));
    }
  }
  
  @override
  Future<dynamic> getData(String key) async {
    return _prefs.get(key);
  }
  
  @override
  Future<void> removeData(String key) async {
    await _prefs.remove(key);
  }
  
  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
  
  @override
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  @override
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  @override
  Future<void> removeSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Дополнительные методы для работы с Hive (для больших объемов данных)
  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }
}

// Фабрика для создания сервиса хранения в зависимости от платформы
class StorageServiceFactory {
  static StorageService create() {
    if (kIsWeb) {
      return WebStorageService();
    } else {
      return MobileStorageService();
    }
  }
}
```

**Обоснование**: Многоуровневая стратегия хранения обеспечивает оптимальное использование различных механизмов хранения в зависимости от платформы и типа данных. `SharedPreferences` используется для небольших настроек, `flutter_secure_storage` - для конфиденциальных данных, а `Hive` - для больших объемов структурированных данных.

**Источники**:
- [shared_preferences на pub.dev](https://pub.dev/packages/shared_preferences)
- [flutter_secure_storage на pub.dev](https://pub.dev/packages/flutter_secure_storage)
- [hive на pub.dev](https://pub.dev/packages/hive)

## Геолокация

### Интеграция с геолокацией (CL: 75%)

Для отслеживания местоположения работников на складе и оптимизации маршрутов рекомендуется использовать пакет `geolocator`.

```dart
// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  // Проверка доступности сервисов геолокации
  static Future<bool> checkLocationServices() async {
    if (kIsWeb) {
      // Проверка поддержки геолокации в браузере
      return await Geolocator.isLocationServiceEnabled();
    }
    
    // Проверка для мобильных устройств
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    // Проверка разрешений
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  // Получение текущего местоположения
  static Future<Position?> getCurrentLocation() async {
    // Проверка доступности геолокации
    bool servicesEnabled = await checkLocationServices();
    if (!servicesEnabled) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Вычисление расстояния между двумя точками (в метрах)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  // Подписка на обновления местоположения
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // минимальное изменение, м
      ),
    );
  }
}
```

**Обоснование**: Пакет `geolocator` обеспечивает унифицированный доступ к службам геолокации на различных платформах, включая Android, iOS и веб, с поддержкой определения местоположения, расчета расстояний и отслеживания перемещений.

**Источники**:
- [geolocator на pub.dev](https://pub.dev/packages/geolocator)
- [W3C Geolocation API](https://www.w3.org/TR/geolocation-API/)

## Печать и генерация PDF

### Интеграция с системами печати (CL: 70%)

Для печати этикеток, документов и отчетов рекомендуется использовать пакеты `pdf` и `printing`.

```dart
// services/print_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PrintService {
  // Генерация и печать этикетки
  static Future<void> printLabel(String name, String barcode) async {
    // Создание PDF-документа
    final pdf = pw.Document();
    
    // Добавление страницы с этикеткой
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Название товара
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Штрих-код
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: barcode,
                  width: 200,
                  height: 80,
                ),
                pw.SizedBox(height: 5),
                pw.Text(barcode),
              ],
            ),
          );
        },
      ),
    );
    
    // Отправка на печать
    await _printPdf(pdf);
  }
  
  // Генерация и печать накладной
  static Future<void> printInvoice(Map<String, dynamic> invoiceData) async {
    // Создание PDF-документа
    final pdf = pw.Document();
    
    // Добавление страницы с накладной
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Center(
                child: pw.Text(
                  'НАКЛАДНАЯ',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Информация о накладной
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Номер: ${invoiceData['number']}'),
                  pw.Text('Дата: ${invoiceData['date']}'),
                ],
              ),
              pw.SizedBox(height: 10),
              
              // Информация о получателе
              pw.Text('Получатель: ${invoiceData['recipient']}'),
              pw.Text('Адрес: ${invoiceData['address']}'),
              pw.SizedBox(height: 20),
              
              // Таблица товаров
              pw.Table.fromTextArray(
                headers: ['Наименование', 'Артикул', 'Кол-во', 'Цена', 'Сумма'],
                data: (invoiceData['items'] as List).map((item) => [
                  item['name'],
                  item['sku'],
                  item['quantity'].toString(),
                  item['price'].toString(),
                  item['total'].toString(),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                border: pw.TableBorder.all(),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 20),
              
              // Итоговая сумма
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Итого: ${invoiceData['totalAmount']}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              // Подписи
              pw.SizedBox(height: 50),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Отпустил: ___________________'),
                      pw.SizedBox(height: 5),
                      pw.Text('(подпись)'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Получил: ___________________'),
                      pw.SizedBox(height: 5),
                      pw.Text('(подпись)'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    // Отправка на печать
    await _printPdf(pdf);
  }
  
  // Общий метод для печати PDF
  static Future<void> _printPdf(pw.Document pdf) async {
    // Получение данных PDF
    final Uint8List pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      // Печать на веб через диалог печати браузера
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } else {
      // Печать на мобильных устройствах
      await Printing.pickPrinter(
        context: null,
      ).then((printer) async {
        if (printer != null) {
          await Printing.directPrintPdf(
            printer: printer,
            onLayout: (PdfPageFormat format) async => pdfBytes,
          );
        }
      });
    }
  }
  
  // Предварительный просмотр PDF
  static Future<void> previewPdf(pw.Document pdf) async {
    final Uint8List pdfBytes = await pdf.save();
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Документ',
      format: PdfPageFormat.a4,
    );
  }
  
  // Сохранение PDF в файл (только для мобильных)
  static Future<String?> savePdf(pw.Document pdf, String fileName) async {
    if (kIsWeb) {
      // Веб: скачивание файла
      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      return null;
    } else {
      // Мобильные: сохранение в файл
      final path = await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );
      return path;
    }
  }
}
```

**Обоснование**: Библиотеки `pdf` и `printing` обеспечивают кросс-платформенное решение для создания и печати PDF-документов, с поддержкой как веб, так и мобильных платформ. Это позволяет реализовать функции печати этикеток, накладных и других документов в складском приложении.

**Источники**:
- [pdf на pub.dev](https://pub.dev/packages/pdf)
- [printing на pub.dev](https://pub.dev/packages/printing)

## Заключение

Интеграция нативных функций является ключевым аспектом разработки кросс-платформенного приложения для управления складом. Использование абстракций и адаптеров для работы с платформенно-зависимыми функциями позволяет обеспечить единый интерфейс при различных реализациях под конкретные платформы. При этом важно учитывать ограничения каждой платформы и предоставлять альтернативные решения, когда прямая интеграция невозможна. 