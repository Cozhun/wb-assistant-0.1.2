import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../services/supply_service.dart';
import '../models/order.dart';

/// Экран сканирования и верификации продуктов
class ScannerScreen extends StatefulWidget {
  /// ID поставки, если сканирование происходит в контексте поставки
  final String? supplyId;
  
  /// ID заказа, если сканирование происходит для конкретного заказа
  final String? orderId;
  
  /// Функция обратного вызова после завершения сканирования
  final VoidCallback? onScanComplete;
  
  /// Режим инвентаризации
  final bool inventoryMode;
  
  /// Элемент инвентаризации (если сканируем конкретный товар)
  final dynamic inventoryItem;
  
  /// ID сессии инвентаризации (если в режиме инвентаризации)
  final String? inventorySessionId;

  const ScannerScreen({
    super.key, 
    this.supplyId, 
    this.orderId,
    this.onScanComplete,
    this.inventoryMode = false,
    this.inventoryItem,
    this.inventorySessionId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final _apiService = ApiService();
  final _supplyService = SupplyService();
  final _barcodeController = TextEditingController();
  late final MobileScannerController _scannerController;
  
  String? _lastScannedBarcode;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  String? _currentOrderId;
  bool _isScanning = false;
  bool _isInSupplyContext = false;
  bool _isInOrderContext = false;
  
  Order? _currentOrder;
  List<Order>? _supplyOrders;
  List<ProductItem> _unverifiedProducts = [];
  int _currentProductIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController();
    
    // Проверяем контекст запуска сканера
    _isInSupplyContext = widget.supplyId != null;
    _isInOrderContext = widget.orderId != null;
    
    if (_isInSupplyContext) {
      if (_isInOrderContext) {
        // Загружаем конкретный заказ
        _loadOrderDetails();
      } else {
        // Загружаем все заказы поставки
        _loadSupplyDetails();
      }
    }
    
    // Автоматически запускаем сканер
    _toggleScanner();
  }
  
  /// Загружаем данные о заказе для верификации
  Future<void> _loadOrderDetails() async {
    if (widget.orderId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final supplies = await _supplyService.getMockSupplies();
      final supply = supplies.firstWhere(
        (s) => s.id == widget.supplyId,
        orElse: () => throw Exception('Поставка не найдена'),
      );
      
      // Находим заказ по ID
      final order = supply.orders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => throw Exception('Заказ не найден'),
      );
      
      // Создаем список продуктов для верификации
      final unverifiedProducts = order.item.products
          .where((p) => !p.isVerified)
          .toList();
      
      setState(() {
        _currentOrder = order;
        _currentOrderId = order.id;
        _unverifiedProducts = unverifiedProducts;
        _currentProductIndex = unverifiedProducts.isEmpty ? -1 : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить данные о заказе: $e';
      });
    }
  }
  
  /// Загружаем данные о поставке для контекста сканирования
  Future<void> _loadSupplyDetails() async {
    if (widget.supplyId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final supplies = await _supplyService.getMockSupplies();
      final supply = supplies.firstWhere(
        (s) => s.id == widget.supplyId,
        orElse: () => throw Exception('Поставка не найдена'),
      );
      
      // Фильтруем заказы, которые ещё не собраны
      final incompleteOrders = supply.orders
          .where((o) => !o.isPacked && !o.impossibleToCollect)
          .toList();
      
      // Автоматически выбираем первый невыполненный заказ из поставки
      Order? firstOrder;
      if (incompleteOrders.isNotEmpty) {
        firstOrder = incompleteOrders.first;
        
        // Создаем список продуктов для верификации
        final unverifiedProducts = firstOrder.item.products
            .where((p) => !p.isVerified)
            .toList();
        
        setState(() {
          _currentOrder = firstOrder;
          _currentOrderId = firstOrder?.id; // Используем оператор ?. для безопасного доступа
          _unverifiedProducts = unverifiedProducts;
          _currentProductIndex = unverifiedProducts.isEmpty ? -1 : 0;
        });
      }
      
      setState(() {
        _supplyOrders = incompleteOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить данные о поставке: $e';
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Проверка разрешений больше не требуется, управляем только состоянием сканера
    if (state == AppLifecycleState.resumed) {
      if (_isScanning) {
        _scannerController.start();
      }
    } else if (state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
  
  /// Запуск сканирования штрих-кода
  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    });
  }
  
  /// Обработка результата сканирования штрих-кода
  void _onBarcodeDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.first.rawValue;
    
    if (barcode == null || barcode.isEmpty || barcode == _lastScannedBarcode) {
      return;
    }
    
    _lastScannedBarcode = barcode;
    
    // Воспроизводим звуковой сигнал об успешном сканировании
    HapticFeedback.mediumImpact();
    
    // Заполняем поле ввода и автоматически отправляем код
    _barcodeController.text = barcode;
    _submitBarcode();
  }
  
  /// Отправка штрих-кода на обработку
  Future<void> _submitBarcode() async {
    final barcode = _barcodeController.text.trim();
    
    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Введите штрих-код';
      });
      return;
    }
    
    // Сбрасываем предыдущие сообщения
    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });
    
    try {
      // Проверяем, что у нас есть текущий заказ и продукты для верификации
      if (_currentOrder == null) {
        throw Exception('Заказ не выбран');
      }
      
      if (_unverifiedProducts.isEmpty) {
        throw Exception('Все продукты уже верифицированы');
      }
      
      if (_currentProductIndex < 0 || _currentProductIndex >= _unverifiedProducts.length) {
        throw Exception('Некорректный индекс продукта');
      }
      
      // Получаем текущий продукт для верификации
      final currentProduct = _unverifiedProducts[_currentProductIndex];
      
      // Проверяем, соответствует ли отсканированный штрихкод текущему продукту
      if (currentProduct.barcode != barcode) {
        throw Exception('Штрих-код не соответствует ожидаемому продукту "${currentProduct.name}"');
      }
      
      // В реальной системе здесь будет API запрос для верификации продукта
      // Имитируем успешную верификацию продукта
      // TODO: Заменить на реальный API вызов
      await Future.delayed(const Duration(milliseconds: 300)); // Имитация задержки сети
      
      // Обновляем статус продукта в заказе
      // Здесь должно быть обновление в БД/API
      
      setState(() {
        // Отмечаем продукт как верифицированный
        _unverifiedProducts.removeAt(_currentProductIndex);
        
        // Если все продукты верифицированы
        if (_unverifiedProducts.isEmpty) {
          _successMessage = 'Все продукты верифицированы! Заказ готов к сборке.';
          _currentProductIndex = -1;
        } else {
          // Переходим к следующему продукту или возвращаемся к началу списка
          _currentProductIndex = _currentProductIndex % _unverifiedProducts.length;
          _successMessage = 'Продукт "${currentProduct.name}" верифицирован. Отсканируйте следующий продукт.';
        }
        
        _isLoading = false;
        _barcodeController.clear();
        _lastScannedBarcode = null;
      });
      
      // Показываем сообщение об успешном сканировании
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_successMessage!),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
      // Если все продукты верифицированы, предлагаем перейти к сборке заказа
      if (_unverifiedProducts.isEmpty) {
        _showCompletionDialog();
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка при сканировании: ${e.toString()}';
        _barcodeController.clear();
        _lastScannedBarcode = null;
      });
      
      // Показываем сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Показывает диалог завершения верификации
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Верификация завершена'),
        content: const Text('Все продукты успешно верифицированы. Перейти к сборке заказа?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Продолжить сканирование'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToOrderAssembly();
            },
            child: const Text('Перейти к сборке'),
          ),
        ],
      ),
    );
  }
  
  /// Переход к сборке заказа
  void _goToOrderAssembly() {
    if (_currentOrder == null) return;
    
    Navigator.of(context).pop(); // Закрываем экран сканера
    
    // Переходим к экрану сборки заказа
    context.push('/orders/packing/${_currentOrder!.id}?supplyId=${widget.supplyId}').then((_) {
      if (widget.onScanComplete != null) {
        widget.onScanComplete!();
      }
    });
  }
  
  /// Выбор другого заказа из поставки
  void _selectOrder(Order order) {
    setState(() {
      _currentOrder = order;
      _currentOrderId = order.id;
      
      // Создаем список продуктов для верификации
      _unverifiedProducts = order.item.products
          .where((p) => !p.isVerified)
          .toList();
      
      _currentProductIndex = _unverifiedProducts.isEmpty ? -1 : 0;
      _successMessage = null;
      _errorMessage = null;
      _barcodeController.clear();
      _lastScannedBarcode = null;
    });
  }
  
  /// Завершение сканирования и возврат к предыдущему экрану
  void _finishScanning() {
    Navigator.of(context).pop();
    if (widget.onScanComplete != null) {
      widget.onScanComplete!();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasUnverifiedProducts = _unverifiedProducts.isNotEmpty && _currentProductIndex >= 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isInOrderContext 
              ? 'Верификация продуктов - Заказ ${_currentOrder?.wbOrderNumber ?? ""}' 
              : 'Сканер верификации'
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishScanning,
            tooltip: 'Завершить и вернуться',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                // Область сканера - 50% экрана
                Expanded(
                  flex: 5,
                  child: _buildScannerArea(),
                ),
                
                // Разделитель
                const Divider(height: 1),
                
                // Область информации о текущем продукте - 50% экрана
                Expanded(
                  flex: 5,
                  child: _buildProductInfo(),
                ),
              ],
            ),
    );
  }
  
  /// Построение области сканера
  Widget _buildScannerArea() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Камера сканера
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
          ),
          
          // Рамка для прицеливания
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Кнопки управления сканером внизу экрана
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Переключение вспышки
                IconButton(
                  icon: Icon(
                    _scannerController.torchEnabled 
                        ? Icons.flash_on 
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                
                // Переключение фронтальной камеры
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                  ),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Построение области информации о продукте
  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Text(
              _isInOrderContext
                  ? 'Верификация продуктов заказа'
                  : 'Верификация продуктов поставки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            // Информация о заказе
            if (_currentOrder != null) ...[
              Text(
                'Заказ №${_currentOrder!.wbOrderNumber}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('Клиент: ${_currentOrder!.customer}'),
              const Divider(),
            ],
            
            // Если нет продуктов для верификации
            if (_unverifiedProducts.isEmpty)
              const Card(
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Все продукты верифицированы',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_currentProductIndex >= 0 && _currentProductIndex < _unverifiedProducts.length) ...[
              // Информация о текущем продукте
              const Text(
                'Отсканируйте:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _unverifiedProducts[_currentProductIndex].imageUrl != null
                            ? Image.network(
                                _unverifiedProducts[_currentProductIndex].imageUrl!,
                                height: 100,
                                width: 100,
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
                      const SizedBox(height: 12),
                      
                      Text(
                        _unverifiedProducts[_currentProductIndex].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          const Text(
                            'Артикул: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_unverifiedProducts[_currentProductIndex].article),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          const Text(
                            'Штрихкод: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_unverifiedProducts[_currentProductIndex].barcode),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          const Text(
                            'Количество: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${_unverifiedProducts[_currentProductIndex].quantity} шт.'),
                        ],
                      ),
                      
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Строка прогресса
              Text(
                'Прогресс верификации: ${_currentOrder!.item.verifiedProductCount}/${_currentOrder!.item.productCount}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _currentOrder!.verificationProgress,
                backgroundColor: Colors.grey[200],
                color: Theme.of(context).colorScheme.primary,
              ),
              
              const SizedBox(height: 16),
              
              // Ручной ввод штрихкода
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Введите штрихкод вручную',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      onSubmitted: (_) => _submitBarcode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitBarcode,
                    child: const Text('ОК'),
                  ),
                ],
              ),
            ],
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Если в контексте поставки, показываем кнопку выбора заказа
            if (_isInSupplyContext && _supplyOrders != null && _supplyOrders!.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Выберите заказ',
                  border: OutlineInputBorder(),
                ),
                value: _currentOrderId,
                items: _supplyOrders!.map((order) {
                  return DropdownMenuItem<String>(
                    value: order.id,
                    child: Text('${order.wbOrderNumber} - ${order.customer}'),
                  );
                }).toList(),
                onChanged: (orderId) {
                  if (orderId != null) {
                    final order = _supplyOrders!.firstWhere((o) => o.id == orderId);
                    _selectOrder(order);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
} 