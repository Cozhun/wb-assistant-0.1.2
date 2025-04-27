import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_client/app/services/auth_service.dart';
import 'package:mobile_client/modules/requests/models/request_model.dart';
import 'package:mobile_client/modules/requests/repositories/request_repository.dart';

/// Экран со списком запросов
class RequestListScreen extends HookWidget {
  const RequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);
    final requests = useState<List<Request>>([]);
    final filteredRequests = useState<List<Request>>([]);
    final selectedStatus = useState<int?>(null);
    final refreshKey = useState(DateTime.now().millisecondsSinceEpoch);

    // Инициализация репозитория
    final authService = AuthService();
    final requestRepository = RequestRepository(authService: authService);

    // Загрузка запросов
    useEffect(() {
      Future<void> loadRequests() async {
        try {
          isLoading.value = true;
          errorMessage.value = null;
          
          final fetchedRequests = await requestRepository.getRequests(
            statusId: selectedStatus.value,
          );
          
          requests.value = fetchedRequests;
          _filterRequests(searchController.text, requests, filteredRequests);
          
        } catch (error) {
          errorMessage.value = error.toString();
        } finally {
          isLoading.value = false;
        }
      }

      loadRequests();
      
      return null;
    }, [refreshKey.value, selectedStatus.value]);

    // Фильтрация запросов при изменении текста поиска
    useEffect(() {
      void onSearchChanged() {
        _filterRequests(searchController.text, requests, filteredRequests);
      }
      
      searchController.addListener(onSearchChanged);
      
      return () => searchController.removeListener(onSearchChanged);
    }, [searchController, requests.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              refreshKey.value = DateTime.now().millisecondsSinceEpoch;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Поиск запросов',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterRequests('', requests, filteredRequests);
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          // Фильтры по статусу
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Все'),
                    selected: selectedStatus.value == null,
                    onSelected: (selected) {
                      if (selected) {
                        selectedStatus.value = null;
                      }
                    },
                  ),
                ),
                // Здесь будут другие фильтры по статусам
              ],
            ),
          ),
          
          // Контент
          Expanded(
            child: _buildContent(
              context, 
              isLoading.value, 
              errorMessage.value, 
              filteredRequests.value,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Переход на экран создания запроса
          // context.push('/requests/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Построение основного контента экрана
  Widget _buildContent(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
    List<Request> requests,
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

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Запросы не найдены',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(context, request);
      },
    );
  }

  // Построение карточки запроса
  Widget _buildRequestCard(BuildContext context, Request request) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final createdAtFormatted = dateFormat.format(request.createdAt);
    
    Color? statusColor;
    if (request.statusColor != null) {
      try {
        statusColor = Color(int.parse(request.statusColor!.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        statusColor = Colors.grey;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/requests/${request.requestId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    request.requestNumber,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (statusColor != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        request.statusName ?? 'Статус',
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (request.description != null && request.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
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
                      _getPriorityText(request.priority),
                      style: TextStyle(
                        color: _getPriorityColor(request.priority),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Создан: $createdAtFormatted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

// Фильтрация запросов
void _filterRequests(
  String query,
  ValueNotifier<List<Request>> requests,
  ValueNotifier<List<Request>> filteredRequests,
) {
  if (query.isEmpty) {
    filteredRequests.value = List.from(requests.value);
    return;
  }

  final lowercaseQuery = query.toLowerCase();
  filteredRequests.value = requests.value.where((request) {
    return request.title.toLowerCase().contains(lowercaseQuery) ||
        request.requestNumber.toLowerCase().contains(lowercaseQuery) ||
        (request.description?.toLowerCase().contains(lowercaseQuery) ?? false);
  }).toList();
} 