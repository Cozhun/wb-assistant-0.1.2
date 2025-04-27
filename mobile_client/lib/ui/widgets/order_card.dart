import 'package:flutter/material.dart';
import '../../modules/orders/models/order.dart';

/// Виджет для отображения карточки заказа
class OrderCard extends StatelessWidget {
  final Order order;
  final bool isWildberries;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    this.isWildberries = false,
    this.onTap,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Определение цвета статуса
    Color statusColor;
    switch (order.status) {
      case 'new':
      case OrderStatus.pending:
        statusColor = Colors.blue;
        break;
      case OrderStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isWildberries ? Colors.purple.withOpacity(0.3) : Colors.transparent,
          width: isWildberries ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isWildberries) ...[
                    const Icon(Icons.shopping_bag, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'WB ${order.wbOrderNumber}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ] else ...[
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      '№${order.id}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Дата создания: ${_formatDate(order.createdAt)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Товаров: ${order.productCount}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Стоимость: ${order.totalAmount} ₽',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onConfirm != null || onCancel != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Отменить'),
                      ),
                    if (onConfirm != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Подтвердить'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Получение текстового представления статуса
  String _getStatusText(String? status) {
    switch (status) {
      case 'new':
      case OrderStatus.pending:
        return 'Новый';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.completed:
        return 'Завершен';
      case OrderStatus.cancelled:
        return 'Отменен';
      case OrderStatus.impossibleToCollect:
        return 'Невозможно собрать';
      case OrderStatus.fulfilled:
        return 'Списан';
      case OrderStatus.verified:
        return 'Проверен';
      case OrderStatus.packed:
        return 'Упакован';
      case OrderStatus.readyToShip:
        return 'Готов к отправке';
      case OrderStatus.shipped:
        return 'Отправлен';
      case OrderStatus.delivered:
        return 'Доставлен';
      default:
        return status ?? 'Неизвестный';
    }
  }
  
  /// Форматирование даты
  String _formatDate(DateTime? date) {
    if (date == null) return 'Неизвестно';
    
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 