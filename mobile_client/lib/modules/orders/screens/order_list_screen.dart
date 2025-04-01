import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../ui/common/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../ui/common/theme/theme_provider.dart';
import '../models/order.dart';
import '../models/supply.dart';
import '../services/supply_service.dart';
import '../services/order_service.dart';

/// Экран списка заказов
class OrderListScreen extends StatefulWidget {
  /// Флаг, показывающий, что это заказы из закрытых поставок
  final bool fromClosedSupplies;
  
  const OrderListScreen({
    super.key, 
    this.fromClosedSupplies = false,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _supplyService = SupplyService();
  final _orderService = OrderService();
  
  late TabController _tabController;
  List<Order> _orders = [];
  List<Order> _impossibleOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.fromClosedSupplies ? 1 : 2, vsync: this);
    _loadOrders();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Загрузка списка заказов
  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Загружаем заказы в зависимости от режима
      if (widget.fromClosedSupplies) {
        // Загрузка заказов из закрытых поставок
        final closedOrders = await _loadOrdersFromClosedSupplies();
        if (!mounted) return;
        setState(() {
          _impossibleOrders = closedOrders;
          _isLoading = false;
        });
      } else {
        // Стандартная загрузка заказов и заказов из закрытых поставок
        // Пытаемся загрузить из кэша
        final cachedOrders = _storageService.getOrders();
        if (cachedOrders != null && cachedOrders.isNotEmpty) {
          _orders = cachedOrders.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList();
          setState(() {}); // Отображаем кэшированные данные
        }
        
        // Загружаем с сервера
        final response = await _apiService.getOrders();
        
        // Преобразуем в модели Order и сортируем по дате
        final fetchedOrders = response
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
            
        fetchedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Сохраняем в кэш
        await _storageService.saveOrders(response);
        
        // Загружаем заказы из закрытых поставок
        final closedOrders = await _loadOrdersFromClosedSupplies();
        
        if (!mounted) return;
        setState(() {
          _orders = fetchedOrders;
          _impossibleOrders = closedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Не удалось загрузить заказы';
        _isLoading = false;
      });
    }
  }
  
  /// Загрузка заказов из закрытых поставок
  Future<List<Order>> _loadOrdersFromClosedSupplies() async {
    // Получаем все поставки
    final supplies = await _supplyService.getSupplies();
    
    // Фильтруем закрытые поставки (shipped, delivered)
    final closedSupplies = supplies.where(
      (supply) => supply.status == SupplyStatus.shipped || 
                 supply.status == SupplyStatus.delivered
    ).toList();
    
    // Извлекаем заказы из закрытых поставок
    final List<Order> impossibleOrders = [];
    for (final supply in closedSupplies) {
      // Фильтруем заказы, которые не были полностью собраны и отмечены как невозможные
      final uncollectedOrders = supply.orders.where(
        (order) => order.isImpossibleToCollect && order.isWithinCollectionWindow
      ).toList();
      
      impossibleOrders.addAll(uncollectedOrders);
    }
    
    // Сортируем по оставшемуся времени (сначала те, у которых меньше времени)
    impossibleOrders.sort((a, b) => a.remainingHours.compareTo(b.remainingHours));
    return impossibleOrders;
  }
  
  /// Переход к деталям заказа
  void _openOrderDetails(String orderId) {
    context.push('/orders/details/$orderId');
  }
  
  /// Обработка заказа из закрытой поставки (списание)
  Future<void> _processImpossibleOrder(Order order) async {
    // Показываем диалог подтверждения
    final dynamic result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Списание заказа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Вы собрали заказ #${order.id} и хотите списать его из системы?'),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Примечание: '),
                    TextSpan(
                      text: 'Убедитесь, что вы прикрепили к заказу оригинальную этикетку товара и стикер заказа.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Оставшееся время: ${order.remainingHours} ч.',
                style: TextStyle(
                  color: _getTimeColor(order.remainingHours),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
              child: const Text('Сбросить фильтры'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop('labels');
              },
              child: const Text('Перейти к этикеткам'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Списать заказ'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Списываем заказ
        final updatedOrder = await _orderService.fulfillImpossibleOrder(order.id);
        
        // Обновляем список
        if (mounted) {
          setState(() {
            _impossibleOrders.removeWhere((o) => o.id == order.id);
            _isLoading = false;
          });
          
          // Показываем уведомление об успехе
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заказ #${order.id} успешно списан'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Показываем уведомление об ошибке
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при списании заказа: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (result == 'labels') {
      // Добавляем небольшую задержку перед навигацией
      await Future.delayed(Duration(milliseconds: 100));
      
      // Переход к экрану печати этикеток, если виджет все еще монтирован
      if (mounted) {
        context.push('/orders/details/${order.id}/labels');
      }
    }
  }
  
  /// Печать этикеток для заказа
  Future<void> _printOrderLabels(Order order) async {
    // Переход к экрану печати этикеток
    context.push('/orders/details/${order.id}/labels');
  }
  
  // Получение цвета в зависимости от оставшегося времени
  Color _getTimeColor(int hours) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    if (hours < 24) {
      return Colors.red;
    } else if (hours < 48) {
      return Colors.orange;
    } else {
      return isDarkMode ? Colors.green[300]! : Colors.green;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromClosedSupplies 
            ? 'Заказы из закрытых поставок' 
            : 'Заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Обновить',
          ),
        ],
        bottom: widget.fromClosedSupplies ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Текущие заказы'),
            Tab(text: 'Из закрытых поставок'),
          ],
        ),
      ),
      body: widget.fromClosedSupplies 
          ? _buildImpossibleOrdersList() 
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(),
                _buildImpossibleOrdersList(),
              ],
            ),
    );
  }
  
  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _isLoading && _orders.isEmpty
          ? const Center(child: LoadingIndicator(size: 40))
          : _orders.isEmpty
              ? const Center(
                  child: Text('Нет активных заказов', style: TextStyle(fontSize: 16)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order, false);
                  },
                ),
    );
  }
  
  Widget _buildImpossibleOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _isLoading && _impossibleOrders.isEmpty
          ? const Center(child: LoadingIndicator(size: 40))
          : _impossibleOrders.isEmpty
              ? const Center(
                  child: Text(
                    'Нет заказов из закрытых поставок\nв 120-часовом окне', 
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _impossibleOrders.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = _impossibleOrders[index];
                    return _buildOrderCard(order, true);
                  },
                ),
    );
  }
  
  Widget _buildOrderCard(Order order, bool isImpossible) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    // Определяем цвет индикатора статуса
    Color statusColor;
    IconData statusIcon;
    
    if (isImpossible) {
      statusColor = _getTimeColor(order.remainingHours);
      statusIcon = Icons.schedule;
    } else {
      switch (order.status.toLowerCase()) {
        case 'новый':
        case 'pending':
          statusColor = Colors.blue;
          statusIcon = Icons.fiber_new;
          break;
        case 'в работе':
        case 'in_progress':
          statusColor = Colors.orange;
          statusIcon = Icons.work;
          break;
        case 'выполнен':
        case 'completed':
        case 'fulfilled':
          statusColor = AppColors.getCompletedStatusColor(isDarkMode);
          statusIcon = Icons.check_circle;
          break;
        case 'отменен':
        case 'cancelled':
          statusColor = AppColors.getCancelledStatusColor(isDarkMode);
          statusIcon = Icons.cancel;
          break;
        case 'impossible_to_collect':
          statusColor = Colors.purple;
          statusIcon = Icons.do_not_disturb_on;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.shopping_bag;
      }
    }
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _openOrderDetails(order.id),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Создан: ${_formatDate(order.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Товаров: ${order.items.length}'),
                        Text('Статус: ${_formatStatus(order.status)}'),
                        if (order.supplyId != null)
                          Text('Поставка: ${order.supplyId}'),
                      ],
                    ),
                  ),
                  if (isImpossible) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Осталось: ${order.remainingHours} ч.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getTimeColor(order.remainingHours),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print),
                              onPressed: () => _printOrderLabels(order),
                              tooltip: 'Печать этикеток',
                              color: isDarkMode ? Colors.blue[300] : Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle),
                              onPressed: () => _processImpossibleOrder(order),
                              tooltip: 'Списать заказ',
                              color: isDarkMode ? Colors.green[300] : Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _openOrderDetails(order.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Форматирование статуса заказа
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Новый';
      case 'in_progress':
        return 'В работе';
      case 'completed':
        return 'Выполнен';
      case 'cancelled':
        return 'Отменен';
      case 'impossible_to_collect':
        return 'Невозможно собрать';
      case 'fulfilled':
        return 'Списан';
      default:
        return status.toLowerCase() == status ? status.substring(0, 1).toUpperCase() + status.substring(1) : status;
    }
  }
  
  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 