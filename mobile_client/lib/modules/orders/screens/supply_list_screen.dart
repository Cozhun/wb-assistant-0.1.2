import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/supply.dart';
import '../services/supply_service.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Экран просмотра и сборки поставок
class SupplyListScreen extends StatefulWidget {
  const SupplyListScreen({super.key});

  @override
  State<SupplyListScreen> createState() => _SupplyListScreenState();
}

class _SupplyListScreenState extends State<SupplyListScreen> {
  final SupplyService _supplyService = SupplyService();
  bool _isLoading = true;
  List<Supply> _supplies = [];
  String? _errorMessage;
  
  // Фильтры
  bool _filterActive = true;
  bool _filterToday = false;
  bool _filterTomorrow = false;
  bool _filterOverdue = false;
  
  @override
  void initState() {
    super.initState();
    _loadSupplies();
  }
  
  /// Загрузка списка поставок с сервера
  Future<void> _loadSupplies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // В реальном приложении используем get-запрос к API
      // Здесь используем mock данные для демонстрации
      final supplies = await _supplyService.getMockSupplies();
      
      if (mounted) {
        setState(() {
          _supplies = supplies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки поставок: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Фильтрация поставок
  List<Supply> _getFilteredSupplies() {
    return _supplies.where((supply) {
      if (_filterActive && !supply.isActive) {
        return false;
      }
      if (_filterToday && !supply.isToday) {
        return false;
      }
      if (_filterTomorrow && !supply.isTomorrow) {
        return false;
      }
      if (_filterOverdue && !supply.isOverdue) {
        return false;
      }
      return true;
    }).toList();
  }
  
  /// Переход к деталям поставки и её сборке
  void _navigateToSupplyDetails(Supply supply) {
    context.go('/supplies/${supply.id}');
  }
  
  /// Продолжение сборки поставки
  void _continueSupplyCollection(Supply supply) {
    _navigateToSupplyDetails(supply);
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredSupplies = _getFilteredSupplies();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои поставки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => context.go('/supplies/closed-orders'),
            tooltip: 'Заказы из закрытых поставок',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupplies,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildBody(filteredSupplies),
    );
  }
  
  Widget _buildBody(List<Supply> supplies) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSupplies,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Информация о статусе смены
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 Статус: В работе', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('⏱️ На смене: 3ч 15м'),
            ],
          ),
        ),
        
        // Фильтры
        Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтры:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('Активные'),
                      selected: _filterActive,
                      onSelected: (value) {
                        setState(() {
                          _filterActive = value;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Сегодня'),
                      selected: _filterToday,
                      onSelected: (value) {
                        setState(() {
                          _filterToday = value;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Завтра'),
                      selected: _filterTomorrow,
                      onSelected: (value) {
                        setState(() {
                          _filterTomorrow = value;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Просроченные'),
                      selected: _filterOverdue,
                      onSelected: (value) {
                        setState(() {
                          _filterOverdue = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Информация о количестве
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Поставок для сборки: ${supplies.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Список поставок
        Expanded(
          child: supplies.isEmpty
              ? const Center(
                  child: Text('Нет поставок, соответствующих фильтрам'),
                )
              : RefreshIndicator(
                  onRefresh: _loadSupplies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: supplies.length,
                    itemBuilder: (context, index) {
                      final supply = supplies[index];
                      return _buildSupplyCard(supply);
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildSupplyCard(Supply supply) {
    final theme = Theme.of(context);
    
    Color statusColor;
    Color progressColor;
    
    switch (supply.status) {
      case SupplyStatus.collecting:
        statusColor = Colors.blue;
        progressColor = Colors.blue;
        break;
      case SupplyStatus.waitingShipment:
        statusColor = Colors.orange;
        progressColor = Colors.green;
        break;
      case SupplyStatus.shipped:
        statusColor = Colors.green;
        progressColor = Colors.green;
        break;
      case SupplyStatus.delivered:
        statusColor = Colors.green.shade900;
        progressColor = Colors.green.shade900;
        break;
      case SupplyStatus.cancelled:
        statusColor = Colors.red;
        progressColor = Colors.red;
        break;
    }
    
    // Форматируем дату
    final day = supply.shipmentDate.day.toString().padLeft(2, '0');
    final month = supply.shipmentDate.month.toString().padLeft(2, '0');
    String formattedDate = '$day.$month.${supply.shipmentDate.year}';
    
    if (supply.isToday) {
      formattedDate = 'Сегодня до ${supply.shipmentDate.hour}:${supply.shipmentDate.minute.toString().padLeft(2, '0')}';
    } else if (supply.isTomorrow) {
      formattedDate = 'Завтра до ${supply.shipmentDate.hour}:${supply.shipmentDate.minute.toString().padLeft(2, '0')}';
    }
    
    // Статус срока
    Widget deadlineWidget;
    if (supply.isOverdue) {
      deadlineWidget = Text(
        'Срок: $formattedDate (просрочен)',
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    } else if (supply.isToday) {
      deadlineWidget = Text(
        'Срок: $formattedDate',
        style: const TextStyle(color: Colors.orange),
      );
    } else {
      deadlineWidget = Text('Срок: $formattedDate');
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AdaptiveCard(
        child: InkWell(
          onTap: () => _navigateToSupplyDetails(supply),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supply.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _getStatusText(supply.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Информация о поставке
                Text('Поставка: ${supply.id}'),
                if (supply.assignedTo != null && supply.assignedTo!.isNotEmpty)
                  Text('Ответственный: ${supply.assignedTo}'),
                
                // Прогресс сборки
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Заказов: ${supply.completedOrders}/${supply.totalOrders}'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: supply.progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                          const SizedBox(height: 4),
                          Text('Прогресс: ${(supply.progress * 100).toInt()}%'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (supply.status == SupplyStatus.collecting)
                      ElevatedButton(
                        onPressed: () => _continueSupplyCollection(supply),
                        child: supply.progress > 0 ? const Text('ПРОДОЛЖИТЬ') : const Text('НАЧАТЬ'),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                        ),
                        onPressed: () => _navigateToSupplyDetails(supply),
                        child: const Text('ДЕТАЛИ'),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                deadlineWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Получение текста статуса поставки
  String _getStatusText(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.collecting:
        return 'В сборке';
      case SupplyStatus.waitingShipment:
        return 'Ожидает отгрузки';
      case SupplyStatus.shipped:
        return 'Отгружена';
      case SupplyStatus.delivered:
        return 'Доставлена';
      case SupplyStatus.cancelled:
        return 'Отменена';
    }
  }
} 