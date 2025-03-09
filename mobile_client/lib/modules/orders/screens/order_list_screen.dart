import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../app/services/storage_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/order.dart';

/// Экран списка заказов
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  /// Загрузка списка заказов
  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
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
      
      if (!mounted) return;
      setState(() {
        _orders = fetchedOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Не удалось загрузить заказы';
        _isLoading = false;
      });
    }
  }
  
  /// Переход к деталям заказа
  void _openOrderDetails(String orderId) {
    context.go('/orders/details/$orderId');
  }
  
  /// Выход из системы
  Future<void> _logout() async {
    await _storageService.clearAll();
    
    if (!mounted) return;
    context.go('/login');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(child: LoadingIndicator(size: 40));
    }
    
    if (_errorMessage != null && _orders.isEmpty) {
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
              onPressed: _loadOrders,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    if (_orders.isEmpty) {
      return const Center(
        child: Text('Нет доступных заказов', style: TextStyle(fontSize: 16)),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _orders.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final order = _orders[index];
        
        // Определяем цвет индикатора статуса
        Color statusColor;
        switch (order.status.toLowerCase()) {
          case 'новый':
            statusColor = Colors.blue;
            break;
          case 'в работе':
            statusColor = Colors.orange;
            break;
          case 'выполнен':
            statusColor = Colors.green;
            break;
          case 'отменен':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }
        
        return Card(
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(Icons.shopping_bag, color: statusColor),
            ),
            title: Text(
              'Заказ #${order.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Статус: ${order.status}'),
                Text('Товаров: ${order.items.length}'),
                Text('Дата: ${_formatDate(order.createdAt)}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openOrderDetails(order.id),
            isThreeLine: true,
          ),
        );
      },
    );
  }
  
  /// Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 