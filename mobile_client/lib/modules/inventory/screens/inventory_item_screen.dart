import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../ui/common/widgets/adaptive_text_field.dart';

/// Экран проверки отдельного элемента инвентаризации
class InventoryItemScreen extends StatefulWidget {
  final String sessionId;
  final InventoryItem item;

  const InventoryItemScreen({
    super.key,
    required this.sessionId,
    required this.item,
  });

  @override
  _InventoryItemScreenState createState() => _InventoryItemScreenState();
}

class _InventoryItemScreenState extends State<InventoryItemScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _isLoading = false;
  bool _isScannerActive = false;
  String? _errorMessage;
  InventoryItem _item = InventoryItem(
    id: '',
    sku: '',
    name: '',
    barcode: '',
    cellCode: '',
    systemQuantity: 0,
  );
  
  int? _actualQuantity;
  String? _comment;
  bool _isFirstScan = true;
  bool _codeMatched = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _actualQuantity = _item.actualQuantity;
    _comment = _item.discrepancyComment;
    
    if (_actualQuantity != null) {
      _quantityController.text = _actualQuantity.toString();
    }
    
    if (_comment != null && _comment!.isNotEmpty) {
      _commentController.text = _comment!;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _commentController.dispose();
    _quantityFocusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// Обновление элемента инвентаризации
  Future<void> _saveItem() async {
    // Проверяем, что количество введено
    if (_actualQuantity == null) {
      _showErrorMessage('Введите фактическое количество');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Обновляем данные элемента
      final updatedItem = _item.copyWith(
        actualQuantity: _actualQuantity,
        status: InventoryStatus.completed,
        discrepancyComment: _comment,
      );
      
      final result = await _inventoryService.updateItem(widget.sessionId, updatedItem);
      
      if (mounted) {
        setState(() {
          _item = result;
          _isLoading = false;
        });
        
        _showSuccessMessage('Товар успешно проверен');
        
        // Возвращаемся к списку с обновленными данными
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка сохранения данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Включение/выключение сканера
  void _toggleScanner() {
    setState(() {
      _isScannerActive = !_isScannerActive;
    });
  }

  /// Обработка отсканированного кода
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    
    final barcode = capture.barcodes.first.rawValue ?? '';
    
    if (barcode.isEmpty) return;
    
    // Проверяем, соответствует ли отсканированный код товару
    if (barcode == _item.barcode) {
      // Остановим сканер после успешного совпадения
      _scannerController.stop();
      
      setState(() {
        _codeMatched = true;
        _isScannerActive = false;
      });
      
      // Показываем сообщение и перенаправляем фокус на поле ввода количества
      _showSuccessMessage('Штрих-код совпал!');
      _quantityFocusNode.requestFocus();
      
      // Если это первое сканирование, автоматически устанавливаем количество как в системе
      if (_isFirstScan && _actualQuantity == null) {
        setState(() {
          _actualQuantity = _item.systemQuantity;
          _quantityController.text = _actualQuantity.toString();
          _isFirstScan = false;
        });
      }
    } else {
      // Показываем сообщение об ошибке
      _showErrorMessage('Штрих-код не совпадает с товаром');
    }
  }

  /// Показ сообщения об успехе
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Показ сообщения об ошибке
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Показывает диалог с подтверждением расхождения
  Future<void> _confirmDiscrepancy() async {
    if (_actualQuantity == null || _actualQuantity == _item.systemQuantity) {
      // Нет расхождения или количество не указано
      return;
    }
    
    final result = await showAppDialogWithActions<bool>(
      context: context,
      title: 'Подтверждение расхождения',
      content: 'Вы указали количество (${_actualQuantity!}) отличное от системного (${_item.systemQuantity}). '
          'Укажите причину расхождения.',
      actions: [
        DialogAction(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: 'Подтвердить',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    
    if (result == true) {
      // Показываем поле для комментария, если его еще нет
      if ((_comment == null || _comment!.isEmpty) && mounted) {
        showAppDialogWithActions<String>(
          context: context,
          title: 'Комментарий к расхождению',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Укажите причину расхождения:'),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Причина расхождения...',
                ),
                autofocus: true,
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
              onPressed: () {
                final comment = _commentController.text.trim();
                setState(() {
                  _comment = comment;
                });
                Navigator.of(context).pop();
                
                // Сохраняем элемент после добавления комментария
                _saveItem();
              },
            ),
          ],
        );
      } else {
        // Если комментарий уже есть, сохраняем элемент
        _saveItem();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Если сканер активен, просто закрываем его
        if (_isScannerActive) {
          setState(() {
            _isScannerActive = false;
          });
          return false;
        }
        
        // В противном случае спрашиваем о сохранении, если есть изменения
        if (_actualQuantity != _item.actualQuantity || _comment != _item.discrepancyComment) {
          final result = await showAppDialogWithActions<bool>(
            context: context,
            title: 'Несохраненные изменения',
            content: 'У вас есть несохраненные изменения. Сохранить их перед выходом?',
            actions: [
              DialogAction(
                label: 'Не сохранять',
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                isDestructive: true,
              ),
              DialogAction(
                label: 'Сохранить',
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
          
          if (result == true) {
            await _saveItem();
          }
        }
        
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_item.name),
          actions: [
            if (!_isScannerActive)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _toggleScanner,
                tooltip: 'Сканировать',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: LoadingIndicator())
            : _isScannerActive
                ? _buildScannerView()
                : _buildFormView(),
        floatingActionButton: !_isScannerActive && !_isLoading
            ? FloatingActionButton.extended(
                onPressed: _actualQuantity != null
                    ? _actualQuantity == _item.systemQuantity
                        ? _saveItem
                        : _confirmDiscrepancy
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('СОХРАНИТЬ'),
                backgroundColor: _actualQuantity != null
                    ? _actualQuantity == _item.systemQuantity
                        ? Colors.green
                        : Colors.orange
                    : Colors.grey,
              )
            : null,
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetected,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Наведите камеру на штрих-код товара: ${_item.barcode}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _toggleScanner,
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о товаре
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_item.imageUrl != null && _item.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _item.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Артикул: ${_item.sku}'),
                            Text('Штрих-код: ${_item.barcode}'),
                            Text('Ячейка: ${_item.cellCode}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Информация о количестве
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Количество по системе:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_item.systemQuantity} шт.',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      
                      if (_codeMatched)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Форма для ввода данных
          Text(
            'Фактическое количество',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          AdaptiveTextField(
            controller: _quantityController,
            focusNode: _quantityFocusNode,
            labelText: 'Количество',
            prefixIcon: const Icon(Icons.library_add_check),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              setState(() {
                _actualQuantity = int.tryParse(value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Показываем комментарий, если есть расхождение
          if (_actualQuantity != null && _actualQuantity != _item.systemQuantity) ...[
            Text(
              'Комментарий к расхождению',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            AdaptiveTextField(
              controller: _commentController,
              labelText: 'Причина расхождения',
              prefixIcon: const Icon(Icons.comment),
              maxLines: 3,
              maxLength: 200,
              onChanged: (value) {
                setState(() {
                  _comment = value;
                });
              },
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Кнопка сканирования
          Center(
            child: ElevatedButton.icon(
              onPressed: _toggleScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('СКАНИРОВАТЬ ШТРИХ-КОД'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
} 