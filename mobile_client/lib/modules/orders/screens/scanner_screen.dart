import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../app/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Экран сканирования
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final _apiService = ApiService();
  final _barcodeController = TextEditingController();
  late final MobileScannerController _scannerController;
  
  String? _lastScannedBarcode;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  String? _currentOrderId;
  bool _isScanning = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController();
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
  
  /// Обработка результата сканирования
  void _onBarcodeDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;
    
    setState(() {
      _isScanning = false;
      _lastScannedBarcode = barcode;
      _barcodeController.text = barcode;
    });
    
    _scannerController.stop();
    
    // Если заказ уже выбран, автоматически отправляем штрих-код
    if (_currentOrderId != null) {
      _submitBarcode();
    }
  }
  
  /// Отправка штрих-кода на сервер
  Future<void> _submitBarcode() async {
    final barcode = _barcodeController.text;
    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Введите или отсканируйте штрих-код';
      });
      return;
    }
    
    if (_currentOrderId == null) {
      setState(() {
        _errorMessage = 'Выберите заказ для сканирования';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final result = await _apiService.scanBarcode(_currentOrderId!, barcode);
      setState(() {
        _isLoading = false;
        _successMessage = 'Товар "${result['name'] ?? 'Неизвестно'}" добавлен в заказ';
        _barcodeController.clear();
        _lastScannedBarcode = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка при сканировании: ${e.toString()}';
      });
    }
  }
  
  /// Выбор заказа
  Future<void> _selectOrder() async {
    final selectedOrderId = await showDialog<String>(
      context: context,
      builder: (context) => const SelectOrderDialog(),
    );
    
    if (selectedOrderId != null) {
      setState(() {
        _currentOrderId = selectedOrderId;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер штрих-кодов'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Карточка выбора заказа
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Заказ', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentOrderId != null
                                ? 'Заказ: $_currentOrderId'
                                : 'Заказ не выбран',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selectOrder,
                          child: const Text('Выбрать'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Карточка сканирования
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сканирование', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    
                    if (_isScanning)
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: _onBarcodeDetect,
                            // Используем встроенные свойства для настройки внешнего вида
                            scanWindow: Rect.fromCenter(
                              center: const Offset(0, 0),
                              width: 300,
                              height: 300,
                            ),
                            overlayBuilder: (p0, p1) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 3,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Штрих-код',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleScanner,
                            icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
                            label: Text(_isScanning ? 'Закрыть сканер' : 'Сканировать'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitBarcode,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Отправить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Сообщения
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_successMessage!),
                  ),
                ),
              ),
              
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Диалог выбора заказа
class SelectOrderDialog extends StatefulWidget {
  const SelectOrderDialog({super.key});

  @override
  State<SelectOrderDialog> createState() => _SelectOrderDialogState();
}

class _SelectOrderDialogState extends State<SelectOrderDialog> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _orders = [];
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    try {
      final orders = await _apiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить заказы: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Выберите заказ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))
            else if (_orders.isEmpty)
              const Text('Нет доступных заказов')
            else
              Flexible(
                child: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return ListTile(
                        title: Text('Заказ ${order['id']}'),
                        subtitle: Text('Статус: ${order['status']}'),
                        onTap: () {
                          Navigator.of(context).pop(order['id'].toString());
                        },
                      );
                    },
                  ),
                ),
              ),
              
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 