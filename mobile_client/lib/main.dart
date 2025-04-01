import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_client/app/routes/app_router.dart';
import 'package:mobile_client/app/services/api_service.dart';
import 'package:mobile_client/app/services/storage_service.dart';
import 'package:mobile_client/ui/common/theme/app_theme.dart';
import 'package:mobile_client/ui/common/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_client/app/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Глобальный экземпляр маршрутизатора
final appRouter = AppRouter().router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Hive для локального хранения
  await Hive.initFlutter();
  
  // Инициализация сервиса хранения (синглтон)
  await StorageService().init();
  
  // Установка ориентации экрана
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем провайдер темы
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Если настройки еще загружаются, показываем заглушку
    if (themeProvider.isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Используем адаптивную тему на основе настроек
    final theme = AppTheme.getTheme(context, isDark: themeProvider.isDarkMode);
    
    return MaterialApp.router(
      title: 'WB Assistant',
      theme: theme,
      routerConfig: appRouter,
      // Добавляем полную поддержку локализации
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский
        Locale('en', 'US'), // Английский
      ],
      locale: const Locale('ru', 'RU'), // Устанавливаем русский по умолчанию
    );
  }
}

// Сохраняем экран для тестирования соединения на случай необходимости
// Раскомментируйте следующее и измените MaterialApp в MyApp для использования
/*
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiService _apiService = ApiService();
  String _connectionStatus = 'Нажмите кнопку для проверки соединения';
  bool _isLoading = false;
  
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Проверка соединения...';
    });
    
    try {
      // Проверяем соединение с API
      final response = await _apiService.testConnection();
      setState(() {
        _connectionStatus = 'Соединение с API установлено!\n'
            'Статус: ${response['status']}\n'
            'Сообщение: ${response['message']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Ошибка соединения: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Попытка авторизации...';
    });
    
    try {
      // Пробуем авторизоваться с тестовыми данными
      final response = await _apiService.login('test', 'password');
      setState(() {
        _connectionStatus = 'Авторизация успешна!\n'
            'Ответ: $response';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Ошибка авторизации: $e';
        _isLoading = false;
      });
    }
  }
  
  // Тестирование явного URL
  Future<void> _testExplicitUrl(String url) async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Проверка соединения с $url...';
    });
    
    try {
      final response = await _apiService.testUrl(url);
      setState(() {
        _connectionStatus = 'Соединение с $url установлено!\n'
            'Статус: ${response['status']}\n'
            'Сообщение: ${response['message']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Ошибка соединения с $url: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка подключения'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _connectionStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _testConnection,
                      child: const Text('Проверить соединение с API'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _testLogin,
                      child: const Text('Проверить авторизацию'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Проверка конкретных URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _testExplicitUrl('http://192.168.1.72'),
                      child: const Text('Проверить IP физического устройства'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _testExplicitUrl('http://10.0.2.2'),
                      child: const Text('Проверить IP эмулятора'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _testExplicitUrl('http://localhost'),
                      child: const Text('Проверить localhost'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Информация о системе:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Устройство: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Другое"}'),
                    Text('Web режим: ${kIsWeb ? "Да" : "Нет"}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
