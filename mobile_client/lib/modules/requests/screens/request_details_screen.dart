import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:mobile_client/app/services/auth_service.dart';
import 'package:mobile_client/modules/requests/models/request_model.dart';
import 'package:mobile_client/modules/requests/models/request_status_model.dart';
import 'package:mobile_client/modules/requests/repositories/request_repository.dart';

/// Экран деталей запроса
class RequestDetailsScreen extends HookWidget {
  final int requestId;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    // Состояния
    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);
    final request = useState<Request?>(null);
    final comments = useState<List<RequestComment>>([]);
    final items = useState<List<RequestItem>>([]);
    final statuses = useState<List<RequestStatus>>([]);
    final refreshKey = useState(DateTime.now().millisecondsSinceEpoch);
    
    // Для комментариев
    final commentController = useTextEditingController();
    final isSubmittingComment = useState(false);
    
    // Для текущей вкладки
    final tabIndex = useState(0);
    
    // Инициализация репозитория
    final authService = AuthService();
    final requestRepository = RequestRepository(authService: authService);

    // Загрузка данных о запросе
    useEffect(() {
      Future<void> loadData() async {
        try {
          isLoading.value = true;
          errorMessage.value = null;
          
          // Загружаем запрос
          final fetchedRequest = await requestRepository.getRequestById(requestId);
          request.value = fetchedRequest;
          
          // Загружаем комментарии
          final fetchedComments = await requestRepository.getRequestComments(requestId);
          comments.value = fetchedComments;
          
          // Загружаем элементы запроса
          final fetchedItems = await requestRepository.getRequestItems(requestId);
          items.value = fetchedItems;
          
          // Загружаем статусы
          final fetchedStatuses = await requestRepository.getRequestStatuses();
          statuses.value = fetchedStatuses.where((s) => s.isActive).toList();
          
        } catch (error) {
          errorMessage.value = error.toString();
        } finally {
          isLoading.value = false;
        }
      }

      loadData();
      
      return null;
    }, [refreshKey.value]);

    // Добавление комментария
    Future<void> addComment() async {
      if (commentController.text.trim().isEmpty) return;
      
      try {
        isSubmittingComment.value = true;
        
        await requestRepository.addRequestComment(
          requestId,
          commentController.text.trim(),
        );
        
        // Очищаем поле и обновляем комментарии
        commentController.clear();
        
        // Обновляем список комментариев
        final fetchedComments = await requestRepository.getRequestComments(requestId);
        comments.value = fetchedComments;
        
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${error.toString()}')),
        );
      } finally {
        isSubmittingComment.value = false;
      }
    }

    // Изменение статуса запроса
    Future<void> changeStatus(int statusId) async {
      try {
        // Показываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изменение статуса...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Обновляем статус
        final updatedRequest = await requestRepository.updateRequestStatus(
          requestId,
          statusId,
        );
        
        // Обновляем данные в UI
        request.value = updatedRequest;
        
        // Показываем уведомление об успешном обновлении
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус успешно изменен')),
        );
        
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${error.toString()}')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: request.value != null
            ? Text('Запрос ${request.value!.requestNumber}')
            : const Text('Детали запроса'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              refreshKey.value = DateTime.now().millisecondsSinceEpoch;
            },
          ),
        ],
      ),
      body: _buildContent(
        context,
        isLoading.value,
        errorMessage.value,
        request.value,
        comments.value,
        items.value,
        statuses.value,
        tabIndex,
        commentController,
        isSubmittingComment.value,
        addComment,
        changeStatus,
      ),
    );
  }
  
  // Построение основного контента экрана
  Widget _buildContent(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
    Request? request,
    List<RequestComment> comments,
    List<RequestItem> items,
    List<RequestStatus> statuses,
    ValueNotifier<int> tabIndex,
    TextEditingController commentController,
    bool isSubmittingComment,
    Future<void> Function() addComment,
    Future<void> Function(int) changeStatus,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки данных',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (request == null) {
      return const Center(
        child: Text('Запрос не найден'),
      );
    }

    return Column(
      children: [
        // Информация о запросе
        _buildRequestHeader(context, request, statuses, changeStatus),
        
        // Вкладки
        TabBar(
          onTap: (index) => tabIndex.value = index,
          tabs: const [
            Tab(text: 'Информация'),
            Tab(text: 'Товары'),
            Tab(text: 'Комментарии'),
          ],
        ),
        
        // Контент вкладки
        Expanded(
          child: IndexedStack(
            index: tabIndex.value,
            children: [
              // Вкладка 1 - Детали запроса
              _buildInfoTab(context, request),
              
              // Вкладка 2 - Товары
              _buildItemsTab(context, items),
              
              // Вкладка 3 - Комментарии
              _buildCommentsTab(
                context, 
                comments, 
                commentController, 
                isSubmittingComment, 
                addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Построение заголовка запроса
  Widget _buildRequestHeader(
    BuildContext context,
    Request request,
    List<RequestStatus> statuses,
    Future<void> Function(int) changeStatus,
  ) {
    Color? statusColor;
    if (request.statusColor != null) {
      try {
        statusColor = Color(int.parse(request.statusColor!.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        statusColor = Colors.grey;
      }
    }
    
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок запроса
          Text(
            request.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          
          // Основная информация
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Номер: ${request.requestNumber}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Создано: ${dateFormat.format(request.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Статус
              PopupMenuButton<int>(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor ?? Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        request.statusName ?? 'Статус',
                        style: TextStyle(
                          color: statusColor ?? Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: statusColor ?? Colors.grey,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  return statuses.map((status) {
                    Color? itemColor;
                    if (status.color != null) {
                      try {
                        itemColor = Color(int.parse(status.color!.substring(1), radix: 16) + 0xFF000000);
                      } catch (_) {
                        itemColor = Colors.grey;
                      }
                    }
                    
                    return PopupMenuItem<int>(
                      value: status.statusId,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: itemColor ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.name),
                        ],
                      ),
                    );
                  }).toList();
                },
                onSelected: (statusId) {
                  if (statusId != request.statusId) {
                    changeStatus(statusId);
                  }
                },
              ),
            ],
          ),
          
          // Приоритет
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getPriorityColor(request.priority).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Приоритет: ${_getPriorityText(request.priority)}',
              style: TextStyle(
                color: _getPriorityColor(request.priority),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Вкладка с информацией о запросе
  Widget _buildInfoTab(BuildContext context, Request request) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Описание
          if (request.description != null && request.description!.isNotEmpty) ...[
            const Text(
              'Описание:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(request.description!),
            const SizedBox(height: 16),
          ],
          
          // Дополнительная информация
          const Text(
            'Дополнительная информация:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoItem('Тип запроса', request.typeName ?? '-'),
          _buildInfoItem('Создан', dateFormat.format(request.createdAt)),
          if (request.updatedAt != null)
            _buildInfoItem('Обновлен', dateFormat.format(request.updatedAt!)),
          if (request.completedAt != null)
            _buildInfoItem('Завершен', dateFormat.format(request.completedAt!)),
          if (request.estimatedCompletionDate != null)
            _buildInfoItem('Плановая дата завершения', 
                          dateFormat.format(request.estimatedCompletionDate!)),
        ],
      ),
    );
  }
  
  // Вкладка с товарами
  Widget _buildItemsTab(BuildContext context, List<RequestItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Нет товаров в запросе',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название и артикул
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? 'Товар #${item.productId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item.sku != null) 
                            Text(
                              'Артикул: ${item.sku}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Количество
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Кол-во: ${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Описание
                if (item.productDescription != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.productDescription!,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                
                // Комментарий
                if (item.comment != null && item.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Комментарий:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.comment!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Вкладка с комментариями
  Widget _buildCommentsTab(
    BuildContext context,
    List<RequestComment> comments,
    TextEditingController commentController,
    bool isSubmittingComment,
    Future<void> Function() addComment,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Column(
      children: [
        // Список комментариев
        Expanded(
          child: comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Нет комментариев',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final formattedDate = dateFormat.format(comment.createdAt);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Автор и дата
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  comment.userName ?? 'Пользователь #${comment.userId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Текст комментария
                            Text(comment.comment),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        // Форма добавления комментария
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Добавить комментарий...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: isSubmittingComment
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: addComment,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.send),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Строка с информацией
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Получение текста приоритета
String _getPriorityText(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.urgent:
      return 'Срочный';
    case RequestPriority.high:
      return 'Высокий';
    case RequestPriority.normal:
      return 'Обычный';
    case RequestPriority.low:
      return 'Низкий';
  }
}

// Получение цвета приоритета
Color _getPriorityColor(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.urgent:
      return Colors.red;
    case RequestPriority.high:
      return Colors.orange;
    case RequestPriority.normal:
      return Colors.blue;
    case RequestPriority.low:
      return Colors.green;
  }
} 