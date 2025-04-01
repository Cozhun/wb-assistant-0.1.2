import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/shift_status.dart';
import '../services/shift_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';

/// Экран управления сменой
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({Key? key}) : super(key: key);

  @override
  _ShiftScreenState createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final ShiftService _shiftService = ShiftService();
  final StorageService _storageService = StorageService();
  
  late ShiftStatus _currentShift;
  bool _isLoading = true;
  String? _userName;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Обновление таймера каждую минуту, если смена активна
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentShift.isActive && mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  /// Загрузка данных пользователя и смены
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Получаем имя пользователя
    if (!_storageService.isInitialized) {
      await _storageService.init();
    }
    
    final userData = _storageService.getUserData();
    final userName = userData?['name'] as String? ?? 'Сотрудник';
    
    // Получаем данные о текущей смене
    final shiftStatus = await _shiftService.getCurrentShift();
    
    if (mounted) {
      setState(() {
        _userName = userName;
        _currentShift = shiftStatus;
        _isLoading = false;
      });
    }
  }
  
  /// Начало смены
  Future<void> _startShift() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final shiftStatus = await _shiftService.startShift();
      
      if (mounted) {
        setState(() {
          _currentShift = shiftStatus;
          _isLoading = false;
        });
        
        _showSuccessMessage('Смена успешно начата');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorMessage('Не удалось начать смену: $e');
      }
    }
  }
  
  /// Завершение смены
  Future<void> _endShift() async {
    try {
      // Используем базовый showDialog вместо шаблонной функции для полного контроля
      final bool? shouldEndShift = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Завершение смены'),
            content: const Text('Вы уверены, что хотите завершить текущую смену?'),
            actions: [
              TextButton(
                onPressed: () {
                  // Просто закрываем диалог с результатом false
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  // Просто закрываем диалог с результатом true
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Завершить'),
              ),
            ],
          );
        },
      );
      
      // Проверяем результат диалога
      if (shouldEndShift != true) {
        return; // Пользователь отменил
      }
      
      // Устанавливаем состояние загрузки
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      // Выполняем завершение смены
      final shiftStatus = await _shiftService.endShift();
      
      // Обновляем UI, только если виджет все еще монтирован
      if (mounted) {
        setState(() {
          _currentShift = shiftStatus;
          _isLoading = false;
        });
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Смена успешно завершена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Обработка ошибок
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorMessage('Не удалось завершить смену: $e');
      }
    }
  }
  
  /// Показ сообщения об успехе
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// Показ сообщения об ошибке
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  /// Переход к экрану заказов
  void _navigateToOrders() {
    context.go('/orders');
  }
  
  /// Переход к экрану запросов
  void _navigateToRequests() {
    context.go('/requests');
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LoadingIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление сменой'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
            tooltip: 'Профиль',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Логотип и приветствие
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Добро пожаловать, $_userName!',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Статус смены
            AdaptiveCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус смены',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    
                    // Показываем информацию о текущей смене или сообщение
                    if (_currentShift.isActive) ...[
                      _buildInfoRow(
                        context, 
                        'Статус:', 
                        'Активна',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildInfoRow(
                        context, 
                        'Начало:', 
                        _formatDateTime(_currentShift.startTime),
                        Icons.timer,
                      ),
                      _buildInfoRow(
                        context, 
                        'Длительность:', 
                        _currentShift.formattedDuration,
                        Icons.timelapse,
                      ),
                      _buildInfoRow(
                        context, 
                        'Собрано заказов:', 
                        '${_currentShift.completedOrders}',
                        Icons.shopping_bag,
                      ),
                    ] else ...[
                      _buildInfoRow(
                        context, 
                        'Статус:', 
                        'Не активна',
                        Icons.cancel,
                        Colors.red,
                      ),
                      if (_currentShift.endTime != null) ...[
                        _buildInfoRow(
                          context, 
                          'Последняя смена:', 
                          _formatDateTime(_currentShift.endTime),
                          Icons.history,
                        ),
                        _buildInfoRow(
                          context, 
                          'Длительность:', 
                          _currentShift.formattedDuration,
                          Icons.timelapse,
                        ),
                        _buildInfoRow(
                          context, 
                          'Собрано заказов:', 
                          '${_currentShift.completedOrders}',
                          Icons.shopping_bag,
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    
                    // Кнопка действия (начать или завершить смену)
                    SizedBox(
                      height: 50,
                      child: _currentShift.isActive
                          ? ElevatedButton(
                              onPressed: _endShift,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                'ЗАВЕРШИТЬ СМЕНУ',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _startShift,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                'НАЧАТЬ СМЕНУ',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Разделы только для активной смены
            if (_currentShift.isActive) ...[
              const SizedBox(height: 24),
              
              // Раздел быстрого доступа
              Text(
                'Быстрый доступ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      context,
                      'Заказы',
                      Icons.shopping_bag_outlined,
                      _navigateToOrders,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickAccessCard(
                      context,
                      'Запросы',
                      Icons.question_answer_outlined,
                      _navigateToRequests,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Статистика
              Text(
                'Статистика',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              AdaptiveCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        context,
                        'Эффективность',
                        '87%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        context,
                        'Среднее время на заказ',
                        '6.2 мин',
                        Icons.timer,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        context,
                        'Точность',
                        '99.5%',
                        Icons.check_circle_outline,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Строка с информацией о смене
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Карточка быстрого доступа
  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AdaptiveCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Строка статистики
  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  /// Форматирование даты и времени
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Н/Д';
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day.$month.${dateTime.year} $hour:$minute';
  }
} 