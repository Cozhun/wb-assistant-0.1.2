import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/warehouse_cell.dart';
import '../services/warehouse_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../ui/common/widgets/adaptive_card.dart';
import '../../../ui/common/widgets/adaptive_dialog.dart';

/// Экран визуализации склада
class WarehouseVisualizationScreen extends StatefulWidget {
  const WarehouseVisualizationScreen({super.key});

  @override
  State<WarehouseVisualizationScreen> createState() => _WarehouseVisualizationScreenState();
}

class _WarehouseVisualizationScreenState extends State<WarehouseVisualizationScreen> {
  final WarehouseService _warehouseService = WarehouseService();
  
  bool _isLoading = true;
  String _currentSection = 'A';
  List<WarehouseCell> _cells = [];
  List<String> _sections = [];
  
  // Фильтры заполненности
  bool _showEmpty = true;
  bool _showLow = true;
  bool _showMedium = true;
  bool _showHigh = true;
  
  // Поиск товара
  final TextEditingController _searchController = TextEditingController();
  List<WarehouseCell> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// Загрузка данных о секциях и ячейках
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Загружаем список секций
      final sections = await _warehouseService.getAllSections();
      
      // Загружаем ячейки текущей секции
      final cells = await _warehouseService.getCellsByZone(_currentSection);
      
      if (mounted) {
        setState(() {
          _sections = sections;
          _cells = cells;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorMessage('Ошибка загрузки данных: $e');
      }
    }
  }
  
  /// Переключение текущей секции
  Future<void> _changeSection(String section) async {
    if (section == _currentSection) return;
    
    setState(() {
      _currentSection = section;
      _isLoading = true;
    });
    
    try {
      final cells = await _warehouseService.getCellsByZone(section);
      
      if (mounted) {
        setState(() {
          _cells = cells;
          _isLoading = false;
          _isSearching = false;
          _searchResults = [];
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorMessage('Ошибка загрузки секции: $e');
      }
    }
  }
  
  /// Поиск товара на складе
  Future<void> _searchItem() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });
    
    try {
      final results = await _warehouseService.findItemLocation(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        
        _showErrorMessage('Ошибка поиска: $e');
      }
    }
  }
  
  /// Инициирование инвентаризации ячейки с возможностью сканирования товаров
  Future<void> _startInventoryForCell(WarehouseCell cell) async {
    try {
      // Запрашиваем пользователя о начале инвентаризации
      final result = await showAppDialogWithActions<bool>(
        context: context,
        title: 'Инвентаризация ячейки ${cell.id}',
        content: 'Инициировать инвентаризацию ячейки ${cell.id}?\n\n'
            'В ячейке должно быть ${cell.articleIds.length} товаров.',
        actions: [
          DialogAction(
            label: 'Отмена',
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          DialogAction(
            label: 'Завершить',
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            isDestructive: true,
          ),
        ],
      );
      
      if (result != true) return;
      
      // Инициируем инвентаризацию на сервере
      await _warehouseService.initiateInventory(cell.id);
      
      // Переходим к экрану сканирования для инвентаризации
      if (!mounted) return;

      // Переходим к экрану сеанса инвентаризации для данной ячейки
      context.push('/inventory/session/${cell.id}', extra: {
        'cell': cell,
        'onComplete': () {
          // Обновляем данные после завершения инвентаризации
          _changeSection(_currentSection);
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при инициировании инвентаризации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Показ деталей ячейки
  Future<void> _showCellDetails(WarehouseCell cell) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ячейка ${cell.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cell.getFillingColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Информация о заполнении
              Text('Секция: ${cell.section}'),
              Text('Позиция: ${cell.position}'),
              Text('Уровень заполнения: ${_getFillingLevelText(cell.fillingLevel)}'),
              
              const SizedBox(height: 16),
              
              // Список товаров
              Text(
                'Товары в ячейке:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              if (cell.articleIds.isEmpty)
                const Text('В ячейке нет товаров')
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cell.articleIds.length,
                    itemBuilder: (context, index) {
                      final articleId = cell.articleIds[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(articleId),
                        dense: true,
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _startInventoryForCell(cell),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ИНВЕНТАРИЗАЦИЯ'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Получение текстового описания уровня заполнения
  String _getFillingLevelText(FillingLevel level) {
    switch (level) {
      case FillingLevel.empty:
        return 'Пусто (<25%)';
      case FillingLevel.low:
        return 'Низкий (25-50%)';
      case FillingLevel.medium:
        return 'Средний (50-75%)';
      case FillingLevel.high:
        return 'Высокий (75-100%)';
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
  
  @override
  Widget build(BuildContext context) {
    // Фильтрация ячеек по заполненности
    final filteredCells = _isSearching 
        ? _searchResults 
        : _cells.where((cell) {
            switch (cell.fillingLevel) {
              case FillingLevel.empty:
                return _showEmpty;
              case FillingLevel.low:
                return _showLow;
              case FillingLevel.medium:
                return _showMedium;
              case FillingLevel.high:
                return _showHigh;
            }
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Визуализация склада'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Выбор секции и информация
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Склад: $_currentSection',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _currentSection,
                        items: _sections.map((section) {
                          return DropdownMenuItem<String>(
                            value: section,
                            child: Text('Секция $section'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _changeSection(value);
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Поиск товара
                  AdaptiveCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Поиск товара',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Введите артикул...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onSubmitted: (_) => _searchItem(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _searchItem,
                                child: const Text('Поиск'),
                              ),
                            ],
                          ),
                          if (_isSearching && _searchResults.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Найдено ячеек: ${_searchResults.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Фильтры заполненности
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фильтры заполнения:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('<25%'),
                            selected: _showEmpty,
                            onSelected: (value) {
                              setState(() {
                                _showEmpty = value;
                              });
                            },
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            selectedColor: Colors.blue.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('25-50%'),
                            selected: _showLow,
                            onSelected: (value) {
                              setState(() {
                                _showLow = value;
                              });
                            },
                            backgroundColor: Colors.green.withOpacity(0.2),
                            selectedColor: Colors.green.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('50-75%'),
                            selected: _showMedium,
                            onSelected: (value) {
                              setState(() {
                                _showMedium = value;
                              });
                            },
                            backgroundColor: Colors.yellow.withOpacity(0.2),
                            selectedColor: Colors.yellow.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('75-100%'),
                            selected: _showHigh,
                            onSelected: (value) {
                              setState(() {
                                _showHigh = value;
                              });
                            },
                            backgroundColor: Colors.red.withOpacity(0.2),
                            selectedColor: Colors.red.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Визуализация ячеек
                  Expanded(
                    child: filteredCells.isEmpty
                        ? const Center(
                            child: Text(
                              'Нет ячеек, соответствующих фильтрам',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : AdaptiveCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: filteredCells.length,
                                itemBuilder: (context, index) {
                                  final cell = filteredCells[index];
                                  return _buildCellItem(cell);
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
  
  /// Построение ячейки склада
  Widget _buildCellItem(WarehouseCell cell) {
    return GestureDetector(
      onTap: () => _showCellDetails(cell),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cell.getFillingColor(),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26),
        ),
        height: 60,
        width: 60,
        child: Stack(
          children: [
            Center(
              child: Text(
                cell.id,
                style: TextStyle(
                  color: cell.getFillingColor().computeLuminance() > 0.5 
                      ? Colors.black 
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Добавляем индикатор количества товаров в ячейке
            if (cell.articleIds.isNotEmpty)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Text(
                    '${cell.articleIds.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 