import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/services/storage_service.dart';
import '../../../ui/common/theme/theme_provider.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_switch.dart';
import '../../../ui/common/widgets/adaptive_text_field.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../ui/common/widgets/responsive_text.dart';
import 'notification_settings_screen.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storageService = StorageService();
  Map<String, dynamic>? _userData;
  bool _isOfflineMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  /// Загрузка данных пользователя
  Future<void> _loadUserData() async {
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final userData = _storageService.getUserData();
    
    if (userData != null) {
      setState(() {
        _userData = userData;
      });
    }
  }
  
  /// Выход из системы
  Future<void> _logout() async {
    try {
      // Используем базовый showDialog для полного контроля
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Выход из системы'),
            content: const Text('Вы уверены, что хотите выйти?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Отмена'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Выйти'),
              ),
            ],
          );
        },
      );
      
      // Если пользователь не подтвердил, выходим
      if (shouldLogout != true) {
        return;
      }
      
      // Очищаем данные
      await _storageService.clearAll();
      
      // Проверяем, что виджет все еще монтирован
      if (!mounted) return;
      
      // Переходим на экран логина
      context.go('/login');
    } catch (e) {
      // Обрабатываем ошибки
      print('Ошибка при выходе из системы: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выходе из системы: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Переключение оффлайн режима
  void _toggleOfflineMode(bool value) {
    setState(() {
      _isOfflineMode = value;
    });
    
    // Тут будет код для включения/выключения оффлайн режима
  }
  
  /// Переход к настройкам уведомлений
  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Получаем провайдер темы
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Профиль пользователя
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ?? 'Пользователь',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _userData?['email'] ?? 'email@example.com',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData?['role'] ?? 'Сборщик',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Настройки приложения
            const ResponsiveText(
              text: 'Настройки приложения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            AdaptiveCard(
              child: Column(
                children: [
                  // Тёмная тема
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              themeProvider.isDarkMode 
                                  ? Icons.dark_mode 
                                  : Icons.light_mode,
                              color: themeProvider.isDarkMode 
                                  ? Colors.amber[300]
                                  : Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            const Text('Тёмная тема'),
                          ],
                        ),
                        AdaptiveSwitch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) => themeProvider.setDarkMode(value),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Оффлайн режим
                  SwitchListTile(
                    title: const Text('Оффлайн режим'),
                    subtitle: const Text('Работа без подключения к интернету'),
                    value: _isOfflineMode,
                    onChanged: _toggleOfflineMode,
                    secondary: const Icon(Icons.wifi_off),
                  ),
                  
                  // Настройка уведомлений
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Настройки уведомлений'),
                    subtitle: const Text('Управление push-уведомлениями'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _navigateToNotificationSettings,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Информация о приложении
            const ResponsiveText(
              text: 'Информация о приложении',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            AdaptiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Версия приложения'),
                    trailing: const Text('0.1.2'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('О приложении'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Переход на экран с информацией о приложении
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Обратная связь'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Переход на экран обратной связи
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Очистка данных
            AdaptiveCard(
              onTap: () {
                // Показать диалог подтверждения очистки кэша
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Очистка кэша'),
                      content: const Text('Вы уверены, что хотите очистить кэш приложения?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            // Сначала закрываем диалог
                            Navigator.of(dialogContext).pop();
                            
                            // Код для очистки кэша
                            await _storageService.clearOrdersCache();
                            
                            // Показываем уведомление об успехе
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Кэш успешно очищен'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Очистить'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const ListTile(
                title: Text('Очистить кэш приложения'),
                trailing: Icon(Icons.delete_outline),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Заметная кнопка для выхода из аккаунта
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Выйти из аккаунта'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 