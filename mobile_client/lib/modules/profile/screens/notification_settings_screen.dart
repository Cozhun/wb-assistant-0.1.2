import 'package:flutter/material.dart';
import '../../../app/services/notification_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Экран настроек уведомлений
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  late Map<String, bool> _settings;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  /// Загрузка настроек уведомлений
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final settings = await NotificationService.getNotificationSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _settings = {
            'new_supply': true,
            'supply_update': true,
            'urgent_supply': true,
            'deadline_reminder': true,
            'shift_status': true,
            'inventory_task': true,
            'system_updates': true,
          };
          _isLoading = false;
          _hasChanges = false;
        });
      }
    }
  }
  
  /// Сохранение настроек уведомлений
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await NotificationService.saveNotificationSettings(_settings);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки уведомлений сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения настроек: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Обновление настройки
  void _updateSetting(String key, bool value) {
    setState(() {
      _settings[key] = value;
      _hasChanges = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка уведомлений'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildSettingsList(),
    );
  }
  
  Widget _buildSettingsList() {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Заголовок раздела
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Типы уведомлений',
            style: theme.textTheme.titleLarge,
          ),
        ),
        
        // Группа: Поставки и заказы
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Поставки и заказы',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSwitchTile(
                  title: 'Новая поставка назначена',
                  subtitle: 'Уведомлять о новых поставках, назначенных вам',
                  value: _settings['new_supply'] ?? true,
                  onChanged: (value) => _updateSetting('new_supply', value),
                ),
                
                _buildSwitchTile(
                  title: 'Изменения в поставке',
                  subtitle: 'Уведомлять об изменениях в назначенных поставках',
                  value: _settings['supply_update'] ?? true,
                  onChanged: (value) => _updateSetting('supply_update', value),
                ),
                
                _buildSwitchTile(
                  title: 'Срочные поставки',
                  subtitle: 'Приоритетные уведомления для срочных поставок',
                  value: _settings['urgent_supply'] ?? true,
                  onChanged: (value) => _updateSetting('urgent_supply', value),
                ),
                
                _buildSwitchTile(
                  title: 'Напоминания о сроках',
                  subtitle: 'Уведомлять о приближающихся дедлайнах',
                  value: _settings['deadline_reminder'] ?? true,
                  onChanged: (value) => _updateSetting('deadline_reminder', value),
                ),
              ],
            ),
          ),
        ),
        
        // Группа: Смены и инвентаризация
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Смены и инвентаризация',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSwitchTile(
                  title: 'Статус смены',
                  subtitle: 'Уведомления об изменении статуса смены',
                  value: _settings['shift_status'] ?? true,
                  onChanged: (value) => _updateSetting('shift_status', value),
                ),
                
                _buildSwitchTile(
                  title: 'Задачи инвентаризации',
                  subtitle: 'Уведомления о назначенных задачах инвентаризации',
                  value: _settings['inventory_task'] ?? true,
                  onChanged: (value) => _updateSetting('inventory_task', value),
                ),
              ],
            ),
          ),
        ),
        
        // Группа: Системные уведомления
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Системные уведомления',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSwitchTile(
                  title: 'Обновления системы',
                  subtitle: 'Уведомления о доступных обновлениях приложения',
                  value: _settings['system_updates'] ?? true,
                  onChanged: (value) => _updateSetting('system_updates', value),
                ),
              ],
            ),
          ),
        ),
        
        // Кнопка "Не беспокоить"
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Режим "Не беспокоить"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'В этом режиме вы не будете получать уведомления в указанное время',
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // В будущем здесь будет переход к настройке периода "Не беспокоить"
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Функция будет доступна в следующей версии'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.do_not_disturb_on),
                    label: const Text('НАСТРОИТЬ ПЕРИОД'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Информация о работе уведомлений
        const SizedBox(height: 24),
        
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Примечание: Уведомления могут приходить с задержкой в зависимости от состояния сети и настроек устройства.',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
} 