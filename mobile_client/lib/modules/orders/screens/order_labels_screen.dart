import 'package:flutter/material.dart';
import '../../../ui/common/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../ui/common/theme/theme_provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';

/// Экран для печати и управления ярлыками заказов
class OrderLabelsScreen extends StatefulWidget {
  /// ID заказа
  final String orderId;
  
  const OrderLabelsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderLabelsScreen> createState() => _OrderLabelsScreenState();
}

class _OrderLabelsScreenState extends State<OrderLabelsScreen> {
  final _orderService = OrderService();
  
  Order? _order;
  bool _isLoading = true;
  bool _orderLabelPrinted = false;
  bool _productLabelPrinted = false;
  
  @override
  void initState() {
    super.initState();
    _loadOrder();
  }
  
  /// Загрузка заказа
  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки заказа: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Печать этикетки товара
  Future<void> _printProductLabel() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Симуляция печати (здесь будет API запрос)
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _productLabelPrinted = true;
          _isLoading = false;
        });
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Этикетка товара отправлена на печать'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка печати этикетки: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Печать стикера заказа
  Future<void> _printOrderLabel() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Симуляция печати (здесь будет API запрос)
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _orderLabelPrinted = true;
          _isLoading = false;
        });
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Стикер заказа отправлен на печать'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка печати стикера: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Печать обеих этикеток
  Future<void> _printBothLabels() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Симуляция печати (здесь будет API запрос)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _productLabelPrinted = true;
          _orderLabelPrinted = true;
          _isLoading = false;
        });
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Обе этикетки отправлены на печать'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка печати этикеток: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Списание заказа
  Future<void> _fulfillOrder() async {
    if (!_orderLabelPrinted || !_productLabelPrinted) {
      // Показываем предупреждение, если не все этикетки напечатаны
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Этикетки не напечатаны'),
          content: const Text(
            'Необходимо напечатать обе этикетки перед списанием заказа.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Списываем заказ
      await _orderService.fulfillImpossibleOrder(_order!.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ успешно списан'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Возвращаемся на предыдущий экран
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка списания заказа: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Этикетки заказа ${widget.orderId}'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _order == null 
              ? const Center(child: Text('Заказ не найден'))
              : _buildContent(isDarkMode),
    );
  }
  
  Widget _buildContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о заказе
          _buildOrderInfo(isDarkMode),
          
          const SizedBox(height: 24),
          
          // Секция этикеток
          Text(
            'Этикетки для печати',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Карточки этикеток
          _buildLabelCard(
            'Этикетка товара',
            'Оригинальная этикетка товара с информацией о продукте',
            Icons.label,
            _productLabelPrinted,
            isDarkMode ? Colors.blue[700]! : Colors.blue,
            _printProductLabel,
          ),
          
          const SizedBox(height: 16),
          
          _buildLabelCard(
            'Стикер заказа',
            'Стикер с номером заказа и данными для идентификации',
            Icons.receipt,
            _orderLabelPrinted,
            isDarkMode ? Colors.purple[700]! : Colors.purple,
            _printOrderLabel,
          ),
          
          const SizedBox(height: 24),
          
          // Кнопка для печати обеих этикеток
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _productLabelPrinted && _orderLabelPrinted
                  ? null
                  : _printBothLabels,
              icon: const Icon(Icons.print),
              label: const Text('Напечатать обе этикетки'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Секция списания заказа
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Списание заказа',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'После печати этикеток вы можете списать заказ из системы. '
                    'Убедитесь, что вы прикрепили напечатанные этикетки к заказу.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !_productLabelPrinted || !_orderLabelPrinted
                          ? null
                          : _fulfillOrder,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Списать заказ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderInfo(bool isDarkMode) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заказ #${_order!.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            // Информация о статусе
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Оставшееся время: ${_order!.remainingHours} ч.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTimeColor(_order!.remainingHours, isDarkMode),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Прогресс бар времени
            LinearProgressIndicator(
              value: _order!.timeProgressPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTimeColor(_order!.remainingHours, isDarkMode),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            
            const SizedBox(height: 16),
            
            // Информация о заказе
            _buildInfoRow('Товары:', '${_order!.items.length} шт.'),
            _buildInfoRow('Поставка:', _order!.supplyId ?? 'Не указана'),
            _buildInfoRow('Причина:', _order!.impossibilityReason ?? 'Не указана'),
            
            const SizedBox(height: 12),
            
            // Примечание об этикетках
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.amber[900] : Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDarkMode ? Colors.amber[100] : Colors.amber[900],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Для списания заказа необходимо распечатать и прикрепить '
                      'к физическому заказу оригинальную этикетку товара и стикер заказа.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.amber[100] : Colors.amber[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLabelCard(
    String title,
    String description,
    IconData icon,
    bool isPrinted,
    Color color,
    VoidCallback onPrint,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(title),
            if (isPrinted) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 18,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 8),
            isPrinted
                ? OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Печатать повторно'),
                  )
                : ElevatedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Печатать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  Color _getTimeColor(int hours, bool isDarkMode) {
    if (hours < 24) {
      return Colors.red;
    } else if (hours < 48) {
      return Colors.orange;
    } else {
      return isDarkMode ? Colors.green[300]! : Colors.green;
    }
  }
} 