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
import '../services/supply_service.dart';

/// Экран упаковки заказа после верификации продуктов
class OrderPackingScreen extends StatefulWidget {
  final String orderId;
  final String? supplyId;
  
  const OrderPackingScreen({
    super.key,
    required this.orderId,
    this.supplyId,
  });

  @override
  State<OrderPackingScreen> createState() => _OrderPackingScreenState();
}

class _OrderPackingScreenState extends State<OrderPackingScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _orderService = OrderService();
  final _supplyService = SupplyService();
  
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLabelPrinting = false;
  bool _isOrderStickerPrinting = false;
  
  // Состояние упаковки продуктов
  List<ProductItem> _productsToPackage = [];
  int _currentProductIndex = 0;
  
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
      // В реальном приложении получаем заказ через API
      // Если есть supplyId, ищем заказ в поставке
      if (widget.supplyId != null) {
        final supplies = await _supplyService.getMockSupplies();
        final supply = supplies.firstWhere(
          (s) => s.id == widget.supplyId,
          orElse: () => throw Exception('Поставка не найдена'),
        );
        
        final order = supply.orders.firstWhere(
          (o) => o.id == widget.orderId,
          orElse: () => throw Exception('Заказ не найден'),
        );
        
        // Проверяем, что все продукты верифицированы
        if (!order.isVerified) {
          throw Exception('Необходимо сначала верифицировать все продукты');
        }
        
        // Создаем список продуктов для упаковки
        final productsToPackage = order.item.products
            .where((p) => !p.isPacked)
            .toList();
        
        setState(() {
          _order = order;
          _productsToPackage = productsToPackage;
          _currentProductIndex = productsToPackage.isEmpty ? -1 : 0;
          _isLoading = false;
        });
      } else {
        // Если нет supplyId, загружаем заказ напрямую
        throw Exception('Не указан ID поставки');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Не удалось загрузить детали заказа: $e';
        _isLoading = false;
      });
    }
  }
  
  /// Пометить продукт как упакованный
  void _markProductAsPacked(int index) {
    if (_productsToPackage.isEmpty || index < 0 || index >= _productsToPackage.length) {
      return;
    }
    
    setState(() {
      // Удаляем продукт из списка ожидающих упаковки
      final product = _productsToPackage.removeAt(index);
      
      // Если все продукты упакованы
      if (_productsToPackage.isEmpty) {
        _currentProductIndex = -1;
        
        // Показываем сообщение об успешной упаковке
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все продукты упакованы!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Переходим к следующему продукту или возвращаемся к началу списка
        _currentProductIndex = _currentProductIndex % _productsToPackage.length;
      }
    });
  }
  
  /// Печать этикетки товара
  Future<void> _printItemLabel() async {
    if (_order == null) return;
    
    setState(() {
      _isLabelPrinting = true;
    });
    
    try {
      // В реальном приложении здесь был бы API запрос на печать этикетки
      // Имитируем задержку печати
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Обновляем состояние заказа 
      setState(() {
        _isLabelPrinting = false;
        
        // Обновляем флаг печати этикетки в заказе
        // В реальном приложении это было бы сделано через API
        _order = _order!.copyWith(isLabelPrinted: true);
      });
      
      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Этикетка товара отправлена на печать'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLabelPrinting = false;
      });
      
      // Показываем уведомление об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка печати этикетки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Печать стикера заказа
  Future<void> _printOrderSticker() async {
    if (_order == null) return;
    
    setState(() {
      _isOrderStickerPrinting = true;
    });
    
    try {
      // В реальном приложении здесь был бы API запрос на печать стикера заказа
      // Имитируем задержку печати
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Обновляем состояние заказа
      setState(() {
        _isOrderStickerPrinting = false;
        
        // Обновляем флаг печати стикера заказа
        // В реальном приложении это было бы сделано через API
        _order = _order!.copyWith(isOrderStickerPrinted: true);
      });
      
      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Стикер заказа отправлен на печать'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isOrderStickerPrinting = false;
      });
      
      // Показываем уведомление об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка печати стикера заказа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Подтверждение завершения сборки заказа
  Future<void> _confirmOrderCompletion() async {
    if (_order == null) return;
    
    // Проверяем, что все необходимые шаги выполнены
    if (!_order!.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Необходимо сначала верифицировать все продукты'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_order!.isPacked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Необходимо упаковать все продукты'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_order!.isLabelPrinted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Необходимо распечатать этикетку товара'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!_order!.isOrderStickerPrinted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Необходимо распечатать стикер заказа'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Показываем диалог подтверждения
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершение сборки заказа'),
        content: const Text(
          'Вы уверены, что хотите завершить сборку заказа? '
          'Этот заказ будет помечен как готовый к отправке.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // В реальном приложении здесь был бы API запрос на завершение сборки заказа
      // Имитируем задержку запроса
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      // Обновляем состояние заказа
      setState(() {
        _isLoading = false;
        
        // Обновляем статус заказа на "ready_to_ship"
        // В реальном приложении это было бы сделано через API
        _order = _order!.copyWith(status: OrderStatus.readyToShip);
      });
      
      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ успешно собран и готов к отправке'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Возвращаемся на экран поставки
      if (widget.supplyId != null) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Показываем уведомление об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка завершения сборки заказа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order == null 
          ? 'Сборка заказа' 
          : 'Сборка заказа №${_order!.wbOrderNumber}'),
        actions: [
          if (_order != null && _order!.isVerified && _order!.isPacked)
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Завершить сборку',
              onPressed: _confirmOrderCompletion,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildOrderView(),
    );
  }
  
  /// Построение экрана с ошибкой
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline, 
            color: Colors.red, 
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Произошла ошибка',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
  
  /// Построение основного экрана заказа
  Widget _buildOrderView() {
    if (_order == null) {
      return const Center(
        child: Text('Информация о заказе отсутствует'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о заказе
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заказ №${_order!.wbOrderNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  // Статус заказа
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_order!.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusText(_order!.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Информация о клиенте
                  Text(
                    'Клиент: ${_order!.customer}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_order!.address != null)
                    Text('Адрес: ${_order!.address}'),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Информация о товаре
                  Text(
                    'Товар: ${_order!.item.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Артикул: ${_order!.item.article}'),
                  Text('Штрихкод: ${_order!.item.barcode}'),
                  Text('Стоимость: ${_order!.totalAmount.toStringAsFixed(2)} ₽'),
                  
                  // Информация о продуктах
                  const SizedBox(height: 16),
                  Text(
                    'Продукты:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Прогресс упаковки
                  LinearProgressIndicator(
                    value: _order!.packingProgress,
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Упаковано: ${_order!.item.packedProductCount}/${_order!.item.productCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Секция для упаковки продуктов
          if (_productsToPackage.isNotEmpty) ...[
            const Text(
              'Упаковка продуктов:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о текущем продукте
                    Center(
                      child: _productsToPackage[_currentProductIndex].imageUrl != null
                          ? Image.network(
                              _productsToPackage[_currentProductIndex].imageUrl!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported, 
                                size: 80,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported, 
                              size: 80,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      _productsToPackage[_currentProductIndex].name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text('Артикул: ${_productsToPackage[_currentProductIndex].article}'),
                    Text('Штрихкод: ${_productsToPackage[_currentProductIndex].barcode}'),
                    Text('Количество: ${_productsToPackage[_currentProductIndex].quantity} шт.'),
                    
                    const SizedBox(height: 16),
                    
                    // Кнопка для отметки о упаковке продукта
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markProductAsPacked(_currentProductIndex),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Продукт упакован'),
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
          
          // Если все продукты упакованы
          if (_productsToPackage.isEmpty && _order!.isPacked) ...[
            const SizedBox(height: 16),
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Все продукты успешно упакованы!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Секция для печати этикеток
          const SizedBox(height: 24),
          const Text(
            'Этикетки и стикеры:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Карточка для печати этикеток
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка для печати этикетки товара
                  ListTile(
                    leading: const Icon(Icons.label),
                    title: const Text('Печать этикетки товара'),
                    subtitle: Text(_order!.isLabelPrinted 
                      ? 'Этикетка распечатана' 
                      : 'Необходимо распечатать этикетку'
                    ),
                    trailing: ElevatedButton(
                      onPressed: _order!.canPrintLabel 
                          ? _printItemLabel 
                          : _order!.isLabelPrinted 
                              ? null 
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Необходимо сначала верифицировать и упаковать все продукты'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                      child: _isLabelPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Печать'),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Кнопка для печати стикера заказа
                  ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Печать стикера заказа'),
                    subtitle: Text(_order!.isOrderStickerPrinted 
                      ? 'Стикер распечатан' 
                      : 'Необходимо распечатать стикер'
                    ),
                    trailing: ElevatedButton(
                      onPressed: _order!.canPrintOrderSticker 
                          ? _printOrderSticker 
                          : _order!.isOrderStickerPrinted 
                              ? null 
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Необходимо сначала упаковать все продукты и распечатать этикетку товара'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                      child: _isOrderStickerPrinting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Печать'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Кнопка завершения сборки
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _order!.isReadyToShip ? _confirmOrderCompletion : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Завершить сборку заказа'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          
          // Подсказка о необходимых действиях
          if (!_order!.isReadyToShip) ...[
            const SizedBox(height: 8),
            Text(
              _getMissingStepsText(),
              style: TextStyle(
                color: Colors.orange.shade800,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  /// Получение текста о недостающих шагах
  String _getMissingStepsText() {
    final List<String> missingSteps = [];
    
    if (!_order!.isVerified) {
      missingSteps.add('верифицировать все продукты');
    }
    
    if (!_order!.isPacked) {
      missingSteps.add('упаковать все продукты');
    }
    
    if (!_order!.isLabelPrinted) {
      missingSteps.add('распечатать этикетку товара');
    }
    
    if (!_order!.isOrderStickerPrinted) {
      missingSteps.add('распечатать стикер заказа');
    }
    
    if (missingSteps.isEmpty) {
      return '';
    }
    
    return 'Для завершения сборки необходимо: ${missingSteps.join(', ')}.';
  }
  
  /// Получение цвета для статуса заказа
  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.impossibleToCollect:
        return Colors.deepOrange;
      case OrderStatus.verified:
        return Colors.teal;
      case OrderStatus.packed:
        return Colors.indigo;
      case OrderStatus.readyToShip:
        return Colors.green.shade800;
      default:
        return Colors.grey;
    }
  }
  
  /// Получение текста для статуса заказа
  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.completed:
        return 'Выполнен';
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.cancelled:
        return 'Отменен';
      case OrderStatus.impossibleToCollect:
        return 'Невозможно собрать';
      case OrderStatus.verified:
        return 'Верифицирован';
      case OrderStatus.packed:
        return 'Упакован';
      case OrderStatus.readyToShip:
        return 'Готов к отправке';
      default:
        return 'Неизвестный статус';
    }
  }
} 