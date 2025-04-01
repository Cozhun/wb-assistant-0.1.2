import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_session.dart';
import '../services/inventory_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_card.dart';

/// Экран списка сеансов инвентаризации
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  List<InventorySession> _sessions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  /// Загрузка сеансов инвентаризации
  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessions = await _inventoryService.getSessions();
      
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки сеансов инвентаризации: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Переход к деталям сеанса инвентаризации
  void _navigateToSessionDetails(InventorySession session) {
    context.go('/inventory/${session.id}');
  }
  
  /// Переход к экрану визуализации склада
  void _navigateToWarehouseVisualization() {
    context.go('/inventory/warehouse-visualization');
  }

  /// Начало нового сеанса инвентаризации
  Future<void> _startSession(InventorySession session) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSession = await _inventoryService.startSession(session.id);
      
      if (mounted) {
        setState(() {
          final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
          if (index >= 0) {
            _sessions[index] = updatedSession;
          }
          _isLoading = false;
        });
        
        // Переходим к деталям сеанса
        _navigateToSessionDetails(updatedSession);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось начать сеанс инвентаризации: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентаризация'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: _navigateToWarehouseVisualization,
            tooltip: 'Визуализация склада',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Обновить',
          ),
        ],
      ),
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
              onPressed: _loadSessions,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Карточка для перехода к визуализации склада
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdaptiveCard(
            child: InkWell(
              onTap: _navigateToWarehouseVisualization,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view,
                      size: 40,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Визуализация склада',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Интерактивная карта склада с уровнями заполнения ячеек',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Заголовок для списка сеансов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Сеансы инвентаризации',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        // Список сеансов
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text('Нет доступных сеансов инвентаризации'),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(InventorySession session) {
    final theme = Theme.of(context);
    
    // Определяем цвет и иконку статуса
    IconData statusIcon;
    Color statusColor;
    
    switch (session.status) {
      case InventorySessionStatus.pending:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        break;
      case InventorySessionStatus.inProgress:
        statusIcon = Icons.play_circle_outline;
        statusColor = Colors.blue;
        break;
      case InventorySessionStatus.completed:
        statusIcon = Icons.check_circle_outline;
        statusColor = Colors.green;
        break;
      case InventorySessionStatus.needsReview:
        statusIcon = Icons.warning_amber_outlined;
        statusColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AdaptiveCard(
        child: InkWell(
          onTap: session.status == InventorySessionStatus.pending
              ? () => _startSession(session)
              : () => _navigateToSessionDetails(session),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Зона: ${session.zone}'),
                const SizedBox(height: 4),
                Text('Назначено: ${session.assignedToUserName}'),
                const SizedBox(height: 8),
                
                // Показываем прогресс, если сеанс уже начат
                if (session.status != InventorySessionStatus.pending) ...[
                  LinearProgressIndicator(
                    value: session.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      session.status == InventorySessionStatus.completed
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Прогресс: ${(session.progress * 100).toInt()}% (${session.completedCount}/${session.items.length})',
                  ),
                  
                  if (session.discrepancyCount > 0)
                    Text(
                      'Расхождения: ${session.discrepancyCount}',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
                
                const SizedBox(height: 8),
                
                // Кнопка действия
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (session.status == InventorySessionStatus.pending)
                      ElevatedButton(
                        onPressed: () => _startSession(session),
                        child: const Text('НАЧАТЬ'),
                      )
                    else if (session.status == InventorySessionStatus.inProgress)
                      ElevatedButton(
                        onPressed: () => _navigateToSessionDetails(session),
                        child: const Text('ПРОДОЛЖИТЬ'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _navigateToSessionDetails(session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: session.status == InventorySessionStatus.completed
                              ? Colors.green
                              : Colors.orange,
                        ),
                        child: Text(
                          session.status == InventorySessionStatus.completed
                              ? 'ПРОСМОТР'
                              : 'ПРОВЕРИТЬ',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 