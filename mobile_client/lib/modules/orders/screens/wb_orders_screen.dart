import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/orders_controller.dart';
import '../models/order.dart';
import '../../../ui/widgets/app_error.dart';
import '../../../ui/widgets/app_loading.dart';
import '../../../ui/widgets/order_card.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_styles.dart';

/// Экран списка заказов Wildberries
class WbOrdersScreen extends StatefulWidget {
  const WbOrdersScreen({super.key});

  @override
  State<WbOrdersScreen> createState() => _WbOrdersScreenState();
}

class _WbOrdersScreenState extends State<WbOrdersScreen> {
  late OrdersController _controller;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    // Инициализация будет в didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Получаем контроллер через Provider
    _controller = Provider.of<OrdersController>(context);
    
    // Проверяем, загружены ли уже заказы
    if (_controller.wbOrders.isEmpty) {
      _controller.loadWildberriesOrders();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы Wildberries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshKey.currentState?.show();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _controller.loadWildberriesOrders,
        child: Consumer<OrdersController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const AppLoading();
            }
            
            if (controller.errorMessage.isNotEmpty) {
              return AppError(
                error: controller.errorMessage,
                onRetry: controller.loadWildberriesOrders,
              );
            }
            
            if (controller.wbOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: AppColors.gray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет заказов Wildberries',
                      style: AppStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Новые заказы появятся здесь автоматически',
                      style: AppStyles.bodyMedium.copyWith(color: AppColors.gray),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.loadWildberriesOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: controller.wbOrders.length,
              itemBuilder: (context, index) {
                final order = controller.wbOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OrderCard(
                    order: order,
                    isWildberries: true,
                    onConfirm: () => _confirmWbOrder(order),
                    onCancel: () => _showCancelDialog(order),
                    onTap: () => _openOrderDetails(order),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  /// Открытие детальной информации о заказе
  void _openOrderDetails(Order order) {
    Navigator.of(context).pushNamed('/orders/${order.id}/details', arguments: {'isWb': true});
  }
  
  /// Подтверждение заказа WB
  Future<void> _confirmWbOrder(Order order) async {
    try {
      await _controller.confirmWbOrder(order.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Заказ #${order.wbOrderNumber} подтвержден'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось подтвердить заказ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Показ диалога отмены заказа
  Future<void> _showCancelDialog(Order order) async {
    final TextEditingController reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите отменить заказ #${order.wbOrderNumber}?'),
            const SizedBox(height: 16),
            const Text('Причина отмены:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Укажите причину',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Необходимо указать причину отмены')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        await _controller.cancelWbOrder(order.id, reasonController.text.trim());
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заказ #${order.wbOrderNumber} отменен'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось отменить заказ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    reasonController.dispose();
  }
} 