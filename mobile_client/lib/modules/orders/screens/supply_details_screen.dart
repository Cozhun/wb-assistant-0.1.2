import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/supply.dart';
import '../models/order.dart';
import '../services/supply_service.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/theme/app_colors.dart';
import '../../../ui/common/theme/theme_provider.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Экран просмотра деталей и сборки поставки
class SupplyDetailsScreen extends StatefulWidget {
  final String supplyId;

  const SupplyDetailsScreen({
    super.key,
    required this.supplyId,
  });

  @override
  State<SupplyDetailsScreen> createState() => _SupplyDetailsScreenState();
}

class _SupplyDetailsScreenState extends State<SupplyDetailsScreen> {
  final SupplyService _supplyService = SupplyService();
  bool _isLoading = true;
  Supply? _supply;
  String? _errorMessage;
  String _supplyId = '';
  
  @override
  void initState() {
    super.initState();
    _supplyId = widget.supplyId;
    _loadSupplyDetails();
  }
  
  /// Загрузка детальной информации о поставке
  Future<void> _loadSupplyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // В реальном приложении используем get-запрос к API
      // Здесь используем mock данные для демонстрации
      final supplies = await _supplyService.getMockSupplies();
      final supply = supplies.firstWhere(
        (s) => s.id == widget.supplyId,
        orElse: () => throw Exception('Поставка не найдена'),
      );
      
      if (mounted) {
        setState(() {
          _supply = supply;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных о поставке: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Начать сканирование товаров для сборки
  void _startScanning() {
    // Переход к экрану сканирования с передачей ID поставки
    context.push('/scanner?supplyId=${widget.supplyId}').then((_) {
      // Обновляем данные о поставке после возврата со сканирования
      _loadSupplyDetails();
    });
  }
  
  /// Переход к экрану заказа для сборки
  void _navigateToOrderVerification(Order order) {
    // Если заказ не может быть собран, показываем предупреждение
    if (order.impossibleToCollect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Невозможно собрать данный заказ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Проверяем, все ли продукты верифицированы
    if (!order.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Необходимо верифицировать все продукты через сканер перед сборкой заказа'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Переходим к экрану сборки заказа
    context.push('/orders/verify/${order.id}?supplyId=${widget.supplyId}').then((_) {
      // Обновляем данные о поставке после возврата
      _loadSupplyDetails();
    });
  }
  
  /// Переход к экрану заказа для просмотра деталей и сборки
  void _navigateToOrder(Order order) {
    // На экране поставки показываем действия в зависимости от стадии заказа
    if (order.status == OrderStatus.pending || order.status == OrderStatus.inProgress) {
      _navigateToOrderVerification(order);
    } else {
      // Переход к экрану просмотра деталей заказа
      context.push('/orders/details/${order.id}?supplyId=${widget.supplyId}').then((_) {
        // Обновляем данные о поставке после возврата
        _loadSupplyDetails();
      });
    }
  }
  
  /// Получение текстового представления статуса
  String _getStatusText(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.collecting:
        return 'В сборке';
      case SupplyStatus.waitingShipment:
        return 'Ожидает отгрузки';
      case SupplyStatus.shipped:
        return 'Отгружена';
      case SupplyStatus.delivered:
        return 'Доставлена';
      case SupplyStatus.cancelled:
        return 'Отменена';
    }
  }
  
  /// Получение текста для статуса поставки
  String _getSupplyStatusText(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.collecting:
        return 'В сборке';
      case SupplyStatus.waitingShipment:
        return 'Ожидает отгрузки';
      case SupplyStatus.shipped:
        return 'Отгружена';
      case SupplyStatus.delivered:
        return 'Доставлена';
      case SupplyStatus.cancelled:
        return 'Отменена';
    }
  }
  
  /// Получение текста для статуса заказа
  String _getOrderStatusText(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.completed:
        return 'Выполнен';
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
      case OrderStatus.shipped:
        return 'Отправлен';
      case OrderStatus.delivered:
        return 'Доставлен';
      default:
        return 'Неизвестный статус';
    }
  }
  
  /// Показывает сборочный лист поставки
  void _showPickingList() {
    if (_supply == null) return;
    
    // Подготавливаем агрегированный список продуктов
    final aggregatedItems = _getAggregatedItems();
    
    // Показываем диалог со сборочным листом
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сборочный лист поставки'),
        content: SizedBox(
          width: double.maxFinite,
          child: aggregatedItems.isEmpty
              ? const Center(child: Text('Нет продуктов для сборки'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: aggregatedItems.length,
                  itemBuilder: (context, index) {
                    final item = aggregatedItems[index];
                    return CheckboxListTile(
                      title: Text(item['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Артикул: ${item['article']}'),
                          Text('Штрихкод: ${item['barcode']}'),
                        ],
                      ),
                      secondary: item['imageUrl'] != null 
                          ? Image.network(
                              item['imageUrl'],
                              width: 50,
                              height: 50,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                            )
                          : null,
                      value: item['verified'] == true,
                      onChanged: null, // Только для просмотра
                      controlAffinity: ListTileControlAffinity.trailing,
                      isThreeLine: true,
                      dense: false,
                      activeColor: Theme.of(context).primaryColor,
                      checkColor: Colors.white,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _startScanning();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Начать сканирование'),
          ),
        ],
      ),
    );
  }
  
  /// Получает агрегированный список товаров для сборочного листа
  List<Map<String, dynamic>> _getAggregatedItems() {
    if (_supply == null) return [];
    
    // Создаем Map для агрегации продуктов по штрихкоду
    final Map<String, Map<String, dynamic>> aggregatedMap = {};
    
    // Проходим по всем заказам и их продуктам
    for (final order in _supply!.orders) {
      // Пропускаем заказы, которые нельзя собрать
      if (order.impossibleToCollect) continue;
      
      // Для каждого продукта в товаре заказа
      for (final product in order.item.products) {
        // Используем штрихкод как уникальный идентификатор
        if (aggregatedMap.containsKey(product.barcode)) {
          // Увеличиваем количество, если продукт уже есть в списке
          aggregatedMap[product.barcode]!['quantity'] = 
              (aggregatedMap[product.barcode]!['quantity'] as int) + product.quantity;
          
          // Считаем продукт верифицированным, если он верифицирован хотя бы в одном заказе
          if (product.isVerified) {
            aggregatedMap[product.barcode]!['verified'] = true;
          }
          
          // Считаем продукт упакованным, если он упакован хотя бы в одном заказе
          if (product.isPacked) {
            aggregatedMap[product.barcode]!['packed'] = true;
          }
        } else {
          // Добавляем новый продукт в список
          aggregatedMap[product.barcode] = {
            'barcode': product.barcode,
            'name': product.name,
            'article': product.article,
            'quantity': product.quantity,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'verified': product.isVerified,
            'packed': product.isPacked,
          };
        }
      }
    }
    
    // Преобразуем Map в List и сортируем по имени
    final result = aggregatedMap.values.toList();
    result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    
    return result;
  }
  
  /// Подтверждение завершения сборки поставки
  Future<void> _confirmSupplyCompletion() async {
    // Получаем статистику по заказам
    final int totalOrders = _supply!.orders.length;
    final int completedOrders = _supply!.orders.where((o) => o.isFullyCollected).length;
    final int impossibleOrders = _supply!.orders.where((o) => o.impossibleToCollect).length;
    final int remainingOrders = totalOrders - completedOrders - impossibleOrders;
    
    final bool hasRemainingOrders = remainingOrders > 0;
    
    // Если есть несобранные заказы (не помеченные как невозможные для сборки), 
    // показываем диалог с предупреждением
    if (hasRemainingOrders) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Завершение сборки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Собрано заказов: $completedOrders из $totalOrders'),
              if (impossibleOrders > 0)
                Text('Невозможно собрать: $impossibleOrders'),
              Text('Осталось собрать: $remainingOrders'),
              const SizedBox(height: 16),
              const Text(
                'В поставке остались несобранные заказы. Вы уверены, что хотите завершить сборку поставки?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Завершить'),
            ),
          ],
        ),
      );
      
      if (result != true) {
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Обновляем статус поставки
      await _supplyService.updateSupplyStatus(
        widget.supplyId, 
        SupplyStatus.waitingShipment
      );
      
      // Перезагружаем детали поставки
      await _loadSupplyDetails();
      
      // Показываем сообщение об успехе
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поставка передана в отгрузку'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_supply?.name ?? 'Детали поставки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Сборочный лист',
            onPressed: _showPickingList,
          ),
          if (_supply != null && _supply!.status == SupplyStatus.collecting)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Передать в отгрузку',
              onPressed: _supply!.completedOrders == 0
                  ? null // Кнопка неактивна, если нет собранных заказов
                  : _confirmSupplyCompletion,
            ),
        ],
      ),
      floatingActionButton: _supply?.status == SupplyStatus.collecting 
          ? FloatingActionButton.extended(
              onPressed: _startScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Сканировать'),
            )
          : null,
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSupplyDetails,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    
    if (_supply == null) {
      return const Center(
        child: Text('Данные о поставке отсутствуют'),
      );
    }
    
    final supply = _supply!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о поставке
          AdaptiveCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          supply.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _buildSupplyStatusBadge(supply.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('ID', supply.id),
                  _buildInfoRow('Создана', _formatDateTime(supply.createdAt)),
                  _buildInfoRow('Срок отгрузки', _formatDateTime(supply.shipmentDate)),
                  if (supply.assignedTo != null && supply.assignedTo!.isNotEmpty)
                    _buildInfoRow('Ответственный', supply.assignedTo!),
                  
                  const SizedBox(height: 16),
                  
                  // Прогресс сборки
                  Text(
                    'Прогресс сборки',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: supply.progress,
                    backgroundColor: Colors.grey[300],
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Собрано: ${supply.completedOrders}/${supply.totalOrders}'),
                      Text('${(supply.progress * 100).toInt()}%'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Рекомендации для сборщика
                  if (supply.status == SupplyStatus.collecting)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Инструкции по сборке:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('1. Отсканируйте товары с помощью кнопки "Сканировать"'),
                          const Text('2. Упакуйте товары в соответствии с инструкциями'),
                          const Text('3. После завершения сборки нажмите "Завершить сборку"'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Заказы в поставке
          Text(
            'Заказы для сборки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          // Список заказов
          if (supply.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('В поставке нет заказов'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: supply.orders.length,
              itemBuilder: (context, index) {
                final order = supply.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
            
          if (supply.status == SupplyStatus.collecting)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: supply.progress == 1.0 
                      ? () {
                          showAppDialogWithActions(
                            context: context,
                            title: 'Завершение сборки',
                            content: 'Вы уверены, что хотите завершить сборку всей поставки?',
                            actions: [
                              DialogAction(
                                label: 'Отмена',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              DialogAction(
                                label: 'Завершить',
                                isPrimary: true,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // В реальном приложении здесь был бы вызов API
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Сборка поставки завершена')),
                                  );
                                },
                              ),
                            ],
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(
                    'ЗАВЕРШИТЬ СБОРКУ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Построение информационной строки
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  /// Построение значка статуса поставки
  Widget _buildSupplyStatusBadge(SupplyStatus status) {
    Color badgeColor;
    
    switch (status) {
      case SupplyStatus.collecting:
        badgeColor = Colors.blue;
        break;
      case SupplyStatus.waitingShipment:
        badgeColor = Colors.orange;
        break;
      case SupplyStatus.shipped:
        badgeColor = Colors.green;
        break;
      case SupplyStatus.delivered:
        badgeColor = Colors.green.shade800;
        break;
      case SupplyStatus.cancelled:
        badgeColor = Colors.red;
        break;
    }
    
    final statusText = _getSupplyStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Построение карточки заказа в списке
  Widget _buildOrderCard(BuildContext context, Order order) {
    final isOverdue = order.dueDate.isBefore(DateTime.now());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToOrderDetails(context, order.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${order.wbOrderNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : null,
                      ),
                    ),
                  ),
                  if (order.impossibleToCollect) 
                    const Chip(
                      label: Text('Невозможно'),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                      padding: EdgeInsets.zero,
                    ),
                  if (!order.impossibleToCollect)
                    _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text('Клиент: ${order.customer}'),
              if (order.address != null) 
                Text('Адрес: ${order.address}', 
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 4),
              // Основной товар заказа
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение товара, если есть
                  if (order.item.imageUrl != null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          order.item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined, 
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Информация о товаре
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (order.item.barcode != null)
                          Text(
                            'Штрихкод: ${order.item.barcode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        Text(
                          'Продуктов: ${order.item.productCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Отображение прогресса сборки заказа
              if (!order.impossibleToCollect) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Прогресс верификации
                    Row(
                      children: [
                        const Text('Верификация:', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: order.verificationProgress,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(order.verificationProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Прогресс упаковки
                    Row(
                      children: [
                        const Text('Упаковка:', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: order.packingProgress,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(order.packingProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              
              // Кнопки действий для заказа
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Кнопка для перехода к сканированию
                  if (!order.impossibleToCollect && !order.isVerified)
                    OutlinedButton.icon(
                      onPressed: () => _navigateToScanner(context, order.id),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Сканировать'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  
                  // Кнопка для перехода к печати этикеток
                  if (order.isVerified && !order.isLabelPrinted) ...[
                    if (!order.impossibleToCollect) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToOrderLabels(context, order.id),
                      icon: const Icon(Icons.label, size: 16),
                      label: const Text('Этикетки'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  
                  // Кнопка для перехода к упаковке заказа
                  if (order.isVerified && !order.isPacked) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToOrderPacking(context, order.id),
                      icon: const Icon(Icons.inventory_2, size: 16),
                      label: const Text('Упаковать'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Переход к экрану упаковки заказа
  void _navigateToOrderPacking(BuildContext context, String orderId) {
    context.go('/orders/$orderId/packing?supplyId=$_supplyId');
  }
  
  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day.$month.$year $hour:$minute';
  }
  
  /// Навигация к экрану с детализацией заказа
  void _navigateToOrderDetails(BuildContext context, String orderId) {
    context.go('/orders/details/$orderId?supplyId=$_supplyId');
  }
  
  /// Навигация к сканеру для верификации продуктов
  void _navigateToScanner(BuildContext context, String orderId) {
    context.go('/scanner?orderId=$orderId&supplyId=$_supplyId');
  }
  
  /// Навигация к экрану печати этикеток
  void _navigateToOrderLabels(BuildContext context, String orderId) {
    context.go('/orders/$orderId/labels?supplyId=$_supplyId');
  }
  
  /// Построение значка статуса заказа
  Widget _buildStatusBadge(String status) {
    final statusColor = _getStatusColor(status);
    final statusText = _getOrderStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Получение цвета для статуса заказа
  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
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
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green.shade900;
      default:
        return Colors.grey;
    }
  }
} 