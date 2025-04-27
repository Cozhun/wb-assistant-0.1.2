import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_session.dart';
import '../models/inventory_item.dart';
import '../models/warehouse_cell.dart';
import '../services/inventory_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../ui/common/widgets/adaptive_text_field.dart';
import 'inventory_item_screen.dart';

/// Экран деталей сеанса инвентаризации
class InventorySessionScreen extends StatefulWidget {
  final String sessionId;
  /// Ячейка склада (опционально, если экран вызван из визуализации склада)
  final WarehouseCell? cell;
  /// Колбэк при завершении инвентаризации
  final VoidCallback? onComplete;

  const InventorySessionScreen({
    super.key,
    required this.sessionId,
    this.cell,
    this.onComplete,
  });

  @override
  _InventorySessionScreenState createState() => _InventorySessionScreenState();
}

class _InventorySessionScreenState extends State<InventorySessionScreen> {
  final InventoryService _inventoryService = InventoryService();
  late InventorySession _session;
  bool _isLoading = true;
  String? _errorMessage;
  String _currentCellFilter = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  /// Загрузка сеанса инвентаризации
  Future<void> _loadSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _inventoryService.getSessionById(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки сеанса инвентаризации: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Завершение сеанса инвентаризации
  Future<void> _completeSession() async {
    // Проверка, все ли элементы проверены
    final uncheckedItems = _session.items.where((item) => !item.isCompleted).length;
    
    if (uncheckedItems > 0) {
      final result = await showAppDialogWithActions<bool>(
        context: context,
        title: 'Не все товары проверены',
        content: 'Вы не проверили $uncheckedItems товаров. Вы действительно хотите завершить инвентаризацию?',
        actions: [
          DialogAction(
            label: 'Отмена',
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          DialogAction(
            label: 'Завершить',
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            isDestructive: true,
          ),
        ],
      );
      
      if (result != true) return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSession = await _inventoryService.completeSession(widget.sessionId);
      
      if (mounted) {
        setState(() {
          _session = updatedSession;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Инвентаризация успешно завершена'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Возвращаемся к списку сеансов
        context.go('/inventory');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось завершить сеанс инвентаризации: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Переход к экрану проверки конкретного товара
  Future<void> _navigateToItemScreen(InventoryItem item) async {
    final result = await Navigator.push<InventoryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryItemScreen(
          sessionId: widget.sessionId,
          item: item,
        ),
      ),
    );
    
    if (result != null && mounted) {
      // Обновляем состояние элемента в списке
      setState(() {
        final index = _session.items.indexWhere((i) => i.id == result.id);
        if (index >= 0) {
          _session.items[index] = result;
          _session.updateStatus();
        }
      });
    }
  }

  /// Фильтрация элементов инвентаризации
  List<InventoryItem> _getFilteredItems() {
    List<InventoryItem> filteredItems = _session.items;
    
    // Фильтрация по ячейке, если задана
    if (_currentCellFilter.isNotEmpty) {
      filteredItems = filteredItems.where((item) => item.cellCode == _currentCellFilter).toList();
    }
    
    // Фильтрация по поисковому запросу, если задан
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        return item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filteredItems;
  }

  /// Получение списка уникальных ячеек
  List<String> _getUniqueCells() {
    final cells = _session.items.map((item) => item.cellCode).toSet().toList();
    cells.sort();
    return cells;
  }

  /// Открытие сканера для инвентаризации товара
  void _openScannerForItem(InventoryItem item) {
    context.push('/scanner', extra: {
      'inventoryMode': true,
      'inventoryItem': item,
      'sessionId': widget.sessionId,
      'onScanComplete': () {
        // Обновляем данные после сканирования
        _loadSession();
      }
    });
  }
  
  /// Переход к экрану сканирования для всего сеанса инвентаризации
  void _startScanning() {
    context.push('/scanner', extra: {
      'inventoryMode': true,
      'sessionId': widget.sessionId,
      'onScanComplete': () {
        // Обновляем данные после сканирования
        _loadSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Инвентаризация')),
        body: const Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Инвентаризация')),
        body: Center(
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
                onPressed: _loadSession,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Инвентаризация ${widget.sessionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSession,
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: _isLoading || _session.isCompleted 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _startScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканировать'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Информация о сеансе
        AdaptiveCard(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(_session.status),
                      color: _getStatusColor(_session.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Зона: ${_session.zone}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(_getStatusText(_session.status)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _session.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _session.status == InventorySessionStatus.completed
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Прогресс: ${(_session.progress * 100).toInt()}% (${_session.completedCount}/${_session.items.length})',
                ),
                if (_session.discrepancyCount > 0)
                  Text(
                    'Расхождения: ${_session.discrepancyCount}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        
        // Фильтры и поиск
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Выпадающий список ячеек
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Ячейка',
                    border: OutlineInputBorder(),
                  ),
                  value: _currentCellFilter.isEmpty ? null : _currentCellFilter,
                  hint: const Text('Все ячейки'),
                  items: [
                    // Опция "Все ячейки"
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Все ячейки'),
                    ),
                    // Список доступных ячеек
                    ..._getUniqueCells().map((cell) => DropdownMenuItem<String>(
                      value: cell,
                      child: Text(cell),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _currentCellFilter = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Кнопка сброса фильтров
              IconButton(
                icon: const Icon(Icons.filter_list_off),
                onPressed: () {
                  setState(() {
                    _currentCellFilter = '';
                    _searchQuery = '';
                  });
                },
                tooltip: 'Сбросить фильтры',
              ),
            ],
          ),
        ),
        
        // Поле поиска
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdaptiveTextField(
            labelText: 'Поиск по названию, артикулу или штрих-коду',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
        ),
        
        // Список товаров
        Expanded(
          child: _buildItemList(),
        ),
      ],
    );
  }

  Widget _buildItemList() {
    final filteredItems = _getFilteredItems();
    
    if (filteredItems.isEmpty) {
      return const Center(
        child: Text('Нет товаров, соответствующих фильтрам'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    // Рассчитываем статус сравнения
    final comparisonStatus = _calculateComparisonStatus(item);
    Color statusColor;
    IconData statusIcon;
    
    switch (comparisonStatus) {
      case 'match':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'mismatch':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
    }
    
    return AdaptiveCard(
      margin: const EdgeInsets.only(bottom: 8.0),
      onTap: () => _navigateToItemScreen(item),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(statusIcon, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text('Артикул: ${item.articleId}'),
            Text('Ячейка: ${item.cellId}'),
            Row(
              children: [
                Text('Система: ${item.expectedQuantity}'),
                const SizedBox(width: 16),
                Text(
                  item.actualQuantity != null
                      ? 'Факт: ${item.actualQuantity}'
                      : 'Не проверено',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.actualQuantity != null
                        ? (item.actualQuantity == item.expectedQuantity
                            ? Colors.green
                            : Colors.red)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Кнопки действий
            if (!_session.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Кнопка сканирования
                    OutlinedButton.icon(
                      onPressed: () => _openScannerForItem(item),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Сканировать'),
                    ),
                    const SizedBox(width: 8),
                    // Кнопка ручного ввода
                    ElevatedButton.icon(
                      onPressed: () => _showQuantityInputDialog(item),
                      icon: const Icon(Icons.edit),
                      label: const Text('Ввести'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(InventorySessionStatus status) {
    switch (status) {
      case InventorySessionStatus.pending:
        return Icons.schedule;
      case InventorySessionStatus.inProgress:
        return Icons.play_circle_outline;
      case InventorySessionStatus.completed:
        return Icons.check_circle_outline;
      case InventorySessionStatus.needsReview:
        return Icons.warning_amber_outlined;
    }
  }

  Color _getStatusColor(InventorySessionStatus status) {
    switch (status) {
      case InventorySessionStatus.pending:
        return Colors.orange;
      case InventorySessionStatus.inProgress:
        return Colors.blue;
      case InventorySessionStatus.completed:
        return Colors.green;
      case InventorySessionStatus.needsReview:
        return Colors.red;
    }
  }

  String _getStatusText(InventorySessionStatus status) {
    switch (status) {
      case InventorySessionStatus.pending:
        return 'Ожидает';
      case InventorySessionStatus.inProgress:
        return 'В процессе';
      case InventorySessionStatus.completed:
        return 'Завершено';
      case InventorySessionStatus.needsReview:
        return 'Требует проверки';
    }
  }

  String _calculateComparisonStatus(InventoryItem item) {
    if (item.actualQuantity == null) {
      return 'pending'; // Ещё не проверено
    } else if (item.actualQuantity == item.expectedQuantity) {
      return 'match'; // Количество совпадает
    } else {
      return 'mismatch'; // Расхождение в количестве
    }
  }

  Future<void> _showQuantityInputDialog(InventoryItem item) async {
    final TextEditingController controller = TextEditingController(
      text: item.actualQuantity?.toString() ?? '',
    );
    
    final result = await showAppDialogWithActions<Map<String, dynamic>>(
      context: context,
      title: 'Ввод количества',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Товар: ${item.name}'),
          Text('Артикул: ${item.sku}'),
          Text('Штрихкод: ${item.barcode}'),
          Text('По системе: ${item.expectedQuantity}'),
          const SizedBox(height: 16),
          AdaptiveTextField(
            controller: controller,
            labelText: 'Фактическое количество',
            keyboardType: TextInputType.number,
          ),
          if (item.actualQuantity != null && item.actualQuantity != item.expectedQuantity)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AdaptiveTextField(
                labelText: 'Комментарий к расхождению',
                initialValue: item.discrepancyComment,
                onChanged: (value) {
                  item.discrepancyComment = value.isNotEmpty ? value : null;
                },
              ),
            ),
        ],
      ),
      actions: [
        DialogAction(
          label: 'Закрыть',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        DialogAction(
          label: 'Сохранить',
          isPrimary: true,
          onPressed: () {
            final actualQuantity = int.tryParse(controller.text);
            if (actualQuantity == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Введите корректное число'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.of(context).pop({
              'actualQuantity': actualQuantity,
              'comment': item.discrepancyComment,
            });
          },
        ),
      ],
    );
    
    if (result != null && result.containsKey('actualQuantity')) {
      final actualQuantity = result['actualQuantity'] as int;
      final updatedItem = item.copyWith(
        actualQuantity: actualQuantity,
        status: actualQuantity == item.expectedQuantity 
            ? InventoryStatus.completed 
            : InventoryStatus.discrepancy,
        discrepancyComment: result['comment'] as String?,
      );
      
      try {
        setState(() {
          _isLoading = true;
        });
        
        // Сохраняем обновленный элемент
        final resultItem = await _inventoryService.updateItem(widget.sessionId, updatedItem);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Обновляем элемент в списке
            final index = _session.items.indexWhere((i) => i.id == resultItem.id);
            if (index >= 0) {
              _session.items[index] = resultItem;
              _session.updateStatus();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Ошибка при обновлении данных: $e';
          });
        }
      }
    }
  }
} 