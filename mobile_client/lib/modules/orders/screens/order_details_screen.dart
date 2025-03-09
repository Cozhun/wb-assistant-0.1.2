import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/order.dart';
import '../models/order_item.dart';

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
  
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
        actions: [
          IconButton(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildBody(),
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
          _buildProgressSection(),
          const SizedBox(height: 24),
          _buildItemsSection(),
        ],
      ),
    );
  }
  
  Widget _buildOrderHeader() {
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
          ],
        ),
      ),
    );
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: item.isCollected ? Colors.green.shade50 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: item.imageUrl.isNotEmpty
            ? Image.network(
                item.imageUrl,
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
              backgroundColor: item.isCollected ? Colors.green : Colors.grey[300],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'новый':
        badgeColor = Colors.blue;
        break;
      case 'в работе':
        badgeColor = Colors.orange;
        break;
      case 'выполнен':
        badgeColor = Colors.green;
        break;
      case 'отменен':
        badgeColor = Colors.red;
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
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Форматирование валюты
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
} 