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
import '../services/order_service.dart';
// import '../models/order_item.dart';

/// Экран деталей заказа
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _orderService = OrderService();
  
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _reasonController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  /// Загрузка деталей заказа
  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Пытаемся загрузить из кэша
      final cachedOrder = _storageService.getOrderDetails(widget.orderId);
      if (cachedOrder != null) {
        _order = Order.fromJson(cachedOrder);
        setState(() {}); // Отображаем кэшированные данные
      }
      
      // Загружаем с сервера
      final response = await _apiService.getOrderDetails(widget.orderId);
      
      // Преобразуем в модель Order
      final fetchedOrder = Order.fromJson(response);
      
      // Сохраняем в кэш
      await _storageService.saveOrderDetails(widget.orderId, response);
      
      if (!mounted) return;
      setState(() {
        _order = fetchedOrder;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Не удалось загрузить детали заказа';
        _isLoading = false;
      });
    }
  }
  
  /// Переход к сканированию
  void _goToScanner() {
    context.go('/scanner', extra: {'orderId': widget.orderId});
  }
  
  /// Отметить заказ как невозможный к сборке
  Future<void> _markAsImpossibleToCollect() async {
    if (_order == null) return;
    
    // Проверяем, не отмечен ли уже заказ как невозможный к сборке
    if (_order!.isImpossibleToCollect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ уже отмечен как невозможный к сборке'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Показываем диалог для ввода причины
    _reasonController.clear();
    final result = await showAppDialogWithActions<bool>(
      context: context,
      title: 'Невозможно собрать заказ',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Отметив заказ как "невозможный к сборке", вы указываете, что '
            'товар в настоящее время отсутствует.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Система даст 120 часов (5 дней) на появление и сборку товара, '
            'после чего заказ нужно будет списать или закрыть.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Причина отсутствия товара',
              hintText: 'Укажите, почему невозможно собрать заказ',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        DialogAction(
          label: 'Отмена',
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        DialogAction(
          label: 'Подтвердить',
          isPrimary: true,
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              // Показываем ошибку, если причина не указана
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Необходимо указать причину'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
    
    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Отмечаем заказ как невозможный к сборке
        final updatedOrder = await _orderService.markOrderAsImpossibleToCollect(
          _order!.id, 
          _reasonController.text.trim(),
        );
        
        if (!mounted) return;
        
        setState(() {
          _order = updatedOrder;
          _isLoading = false;
        });
        
        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Заказ #${_order!.id} отмечен как невозможный к сборке. '
              'У вас есть 120 часов для его обработки.'
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        // Показываем уведомление об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
        actions: [
          // Кнопка для печати этикеток, если заказ невозможно собрать
          if (_order != null && _order!.isImpossibleToCollect)
            IconButton(
              onPressed: () => context.push('/orders/details/${widget.orderId}/labels'),
              icon: const Icon(Icons.print),
              tooltip: 'Печать этикеток',
            ),
          // Кнопка для отметки заказа как невозможного к сборке
          if (_order != null && !_order!.isImpossibleToCollect && !_order!.isFullyCollected)
            IconButton(
              onPressed: _markAsImpossibleToCollect,
              icon: const Icon(Icons.do_not_disturb_on),
              tooltip: 'Невозможно собрать',
            ),
          IconButton(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isLoading)
            const LoadingIndicator(isOverlay: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToScanner,
        tooltip: 'Сканировать',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading && _order == null) {
      return const Center(child: LoadingIndicator(size: 40));
    }
    
    if (_errorMessage != null && _order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    if (_order == null) {
      return const Center(
        child: Text('Информация о заказе недоступна', style: TextStyle(fontSize: 16)),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(),
          const Divider(height: 32),
          if (_order!.isImpossibleToCollect)
            _buildImpossibilitySection(),
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildItemsSection(),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildOrderHeader() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заказ #${_order!.id}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Статус: ', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusBadge(_order!.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Создан: ${_formatDate(_order!.createdAt)}'),
            const SizedBox(height: 8),
            Text('Товаров: ${_order!.totalQuantity}'),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${_formatCurrency(_order!.totalAmount)} ₽',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_order!.supplyId != null) ...[
              const SizedBox(height: 8),
              Text('Поставка: ${_order!.supplyId}'),
            ],
            if (_order!.isImpossibleToCollect) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.purple[900] : Colors.purple[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.do_not_disturb_on,
                      color: isDarkMode ? Colors.white : Colors.purple[800],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Невозможно собрать заказ',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.purple[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildImpossibilitySection() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    // Вычисляем оставшееся время и цвет
    final hoursLeft = _order!.remainingHours;
    final Color timeColor = _getTimeColor(hoursLeft);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: timeColor),
                const SizedBox(width: 8),
                Text(
                  'Время на сборку',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Причина: ${_order!.impossibilityReason ?? "Не указана"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Отмечено: ${_formatDate(_order!.impossibilityDate ?? DateTime.now())}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _order!.timeProgressPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(timeColor),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Осталось: $hoursLeft ч.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: timeColor,
                  ),
                ),
                Text(
                  '${_order!.timeProgressPercentage.toStringAsFixed(0)}% времени истекло',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Если товар появится в наличии, соберите заказ. '
              'В противном случае, по истечении времени заказ нужно будет списать.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/orders/details/${widget.orderId}/labels'),
                icon: const Icon(Icons.print),
                label: const Text('Печать и списание заказа'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.blue[700] : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  
  Widget _buildProgressSection() {
    final progress = _order!.collectionProgress;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс сборки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Text(
              'Собрано ${_order!.collectedQuantity} из ${_order!.totalQuantity} товаров (${(progress * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Товары',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _order!.items.length,
          itemBuilder: (context, index) {
            return _buildItemCard(_order!.items[index]);
          },
        ),
      ],
    );
  }
  
  Widget _buildItemCard(OrderItem item) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: item.isCollected 
          ? (isDarkMode ? Colors.green.shade900 : Colors.green.shade50) 
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                item.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60),
              )
            : const Icon(Icons.shopping_bag, size: 60),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Артикул: ${item.id}'),
            Text('Штрихкод: ${item.barcode}'),
            Text('Количество: ${item.quantity} шт.'),
            Text('Цена: ${_formatCurrency(item.price)} ₽'),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                item.isCollected ? 'Собран' : 'Не собран',
                style: TextStyle(
                  color: item.isCollected ? Colors.white : Colors.black,
                ),
              ),
              backgroundColor: item.isCollected 
                  ? (isDarkMode ? Colors.green : Colors.green) 
                  : Colors.grey[300],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  Widget _buildStatusBadge(String status) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'новый':
      case 'pending':
        badgeColor = Colors.blue;
        break;
      case 'в работе':
      case 'in_progress':
        badgeColor = Colors.orange;
        break;
      case 'выполнен':
      case 'completed':
      case 'fulfilled':
        badgeColor = AppColors.getCompletedStatusColor(isDarkMode);
        break;
      case 'отменен':
      case 'cancelled':
        badgeColor = AppColors.getCancelledStatusColor(isDarkMode);
        break;
      case 'impossible_to_collect':
        badgeColor = Colors.purple;
        break;
      default:
        badgeColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
  
  /// Форматирование валюты
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
  
  /// Построение кнопок действий для заказа
  Widget _buildActionButtons() {
    if (_order == null) return Container();
    final bool canTakeAction = !_isLoading && !_order!.impossibleToCollect;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Кнопка для перехода к сканированию
          if (canTakeAction && !_order!.isVerified)
            ElevatedButton.icon(
              onPressed: _goToScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканировать продукты'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          // Кнопка для перехода к печати этикеток
          if (canTakeAction && _order!.isVerified && !_order!.isLabelPrinted)
            ElevatedButton.icon(
              onPressed: () => context.push('/orders/details/${widget.orderId}/labels'),
              icon: const Icon(Icons.label),
              label: const Text('Печать этикеток'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          // Кнопка для перехода к упаковке заказа
          if (canTakeAction && _order!.isVerified && !_order!.isPacked)
            ElevatedButton.icon(
              onPressed: _navigateToOrderPacking,
              icon: const Icon(Icons.inventory_2),
              label: const Text('Упаковать заказ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Кнопка для отметки заказа как невозможного для сборки
          if (canTakeAction && !_order!.isVerified)
            OutlinedButton.icon(
              onPressed: _markAsImpossibleToCollect,
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text(
                'Отметить как невозможный',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Переход к экрану упаковки заказа
  void _navigateToOrderPacking() {
    if (_order!.supplyId != null) {
      context.go('/orders/${_order!.id}/packing?supplyId=${_order!.supplyId}');
    } else {
      context.go('/orders/${_order!.id}/packing');
    }
  }
} 