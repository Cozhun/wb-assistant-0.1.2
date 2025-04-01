# Управление состоянием

## Обзор

В данном документе описаны подходы к управлению состоянием в кросс-платформенном Flutter-приложении WB Assistant. Правильное управление состоянием является критически важным для создания отзывчивого, предсказуемого и тестируемого приложения, особенно в контексте сложной бизнес-логики складского учета.

## Выбор подхода к управлению состоянием (CL: 90%)

Для проекта WB Assistant рекомендуется использовать комбинацию из нескольких подходов к управлению состоянием, с основным упором на библиотеку **Riverpod**. Данный выбор обусловлен следующими факторами:

1. **Предсказуемость и тестируемость** - Riverpod обеспечивает лучшую тестируемость по сравнению с Provider и другими решениями.
2. **Поддержка асинхронных операций** - Встроенная поддержка асинхронного состояния через `FutureProvider` и `StreamProvider`.
3. **Отсутствие контекста** - Независимость от `BuildContext`, что упрощает доступ к состоянию из любой части приложения.
4. **Типобезопасность** - Полная поддержка статической типизации и автодополнения в IDE.
5. **Простота рефакторинга** - Модульная структура, позволяющая легко изменять и поддерживать код.

**Источники**:
- [Riverpod на pub.dev](https://pub.dev/packages/flutter_riverpod)
- [Официальная документация Riverpod](https://riverpod.dev/)
- [Сравнение подходов управления состоянием от Google](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)

## Архитектура управления состоянием

### Общая структура (CL: 85%)

Рекомендуется использовать многослойную архитектуру с разделением ответственности:

```
lib/
├── models/             # Модели данных (DTO)
├── providers/          # Провайдеры Riverpod
│   ├── state/          # Определения состояний
│   └── services/       # Сервисные провайдеры
├── repositories/       # Репозитории для работы с данными
├── services/           # Бизнес-логика и внешние сервисы
└── ui/                 # Пользовательский интерфейс
```

### Определение провайдеров

```dart
// providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

// Репозиторий аутентификации
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Текущее состояние аутентификации
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Провайдер текущего пользователя
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    authenticated: (user) => user,
    unauthenticated: () => null,
    loading: () => null,
    error: (_) => null,
  );
});
```

### Определение состояний

```dart
// providers/state/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  // Состояние загрузки
  const factory AuthState.loading() = _Loading;
  
  // Состояние аутентификации
  const factory AuthState.authenticated(User user) = _Authenticated;
  
  // Состояние отсутствия аутентификации
  const factory AuthState.unauthenticated() = _Unauthenticated;
  
  // Состояние ошибки
  const factory AuthState.error(String message) = _Error;
}
```

### Управление состоянием (StateNotifier)

```dart
// providers/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import 'state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  
  AuthNotifier(this._repository) : super(const AuthState.loading()) {
    // При создании проверяем текущую сессию
    _checkCurrentSession();
  }
  
  // Проверка текущей сессии
  Future<void> _checkCurrentSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  // Метод входа в систему
  Future<void> signIn(String login, String password) async {
    state = const AuthState.loading();
    
    try {
      final user = await _repository.signIn(login, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  // Метод выхода из системы
  Future<void> signOut() async {
    state = const AuthState.loading();
    
    try {
      await _repository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}
```

## Управление асинхронными данными

### Использование FutureProvider для запросов (CL: 85%)

Для получения данных с сервера рекомендуется использовать `FutureProvider`:

```dart
// providers/warehouse_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/warehouse_cell.dart';
import '../repositories/warehouse_repository.dart';

// Репозиторий склада
final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  return WarehouseRepository();
});

// Провайдер списка ячеек склада
final warehouseCellsProvider = FutureProvider<List<WarehouseCell>>((ref) async {
  final repository = ref.watch(warehouseRepositoryProvider);
  return repository.getCells();
});

// Провайдер для конкретной ячейки по ID
final warehouseCellProvider = FutureProvider.family<WarehouseCell, String>((ref, id) async {
  final repository = ref.watch(warehouseRepositoryProvider);
  return repository.getCellById(id);
});
```

### Использование StreamProvider для реального времени (CL: 80%)

Для отслеживания изменений в реальном времени (например, статусов задач) рекомендуется использовать `StreamProvider`:

```dart
// providers/task_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

// Репозиторий задач
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Провайдер активных задач пользователя
final activeTasksProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    // Если пользователь не авторизован, возвращаем пустой поток
    return Stream.value([]);
  }
  
  // Получаем поток задач для текущего пользователя
  return repository.watchActiveTasksForUser(user.id);
});
```

## Кэширование данных (CL: 75%)

Для оптимизации производительности и поддержки офлайн-режима рекомендуется использовать кэширование:

```dart
// providers/cached_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

// Сервис хранения
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageServiceFactory.create();
});

// Репозиторий товаров
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ProductRepository(storageService);
});

// Провайдер кэшированных товаров с автоматическим обновлением
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  
  try {
    // Сначала пытаемся загрузить данные из кэша
    final cachedProducts = await repository.getProductsFromCache();
    
    // Если в кэше есть данные, сразу их возвращаем
    if (cachedProducts.isNotEmpty) {
      // Асинхронно обновляем данные с сервера
      _updateProductsFromServer(ref, repository);
      return cachedProducts;
    }
    
    // Если кэш пуст, загружаем с сервера
    final products = await repository.getProductsFromServer();
    await repository.saveProductsToCache(products);
    return products;
  } catch (e) {
    // В случае ошибки пытаемся вернуть данные из кэша
    final cachedProducts = await repository.getProductsFromCache();
    if (cachedProducts.isNotEmpty) {
      return cachedProducts;
    }
    // Если и кэш пуст, прокидываем ошибку
    rethrow;
  }
});

// Вспомогательная функция для обновления данных в фоне
Future<void> _updateProductsFromServer(
  ProviderRef ref,
  ProductRepository repository,
) async {
  try {
    final products = await repository.getProductsFromServer();
    await repository.saveProductsToCache(products);
    // Обновляем состояние, чтобы виджеты получили новые данные
    ref.refresh(productsProvider);
  } catch (_) {
    // Игнорируем ошибку обновления - пользователь продолжит работать с кэшем
  }
}
```

## Управление фильтрами и параметрами поиска (CL: 80%)

Для управления фильтрами и параметрами поиска рекомендуется использовать провайдеры состояния:

```dart
// providers/filter_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_providers.freezed.dart';

// Модель параметров фильтрации заказов
@freezed
class OrderFilterParams with _$OrderFilterParams {
  const factory OrderFilterParams({
    // Диапазон дат
    DateTime? startDate,
    DateTime? endDate,
    // Статус заказа
    String? status,
    // Текст поиска
    String? searchText,
    // Сортировка
    @Default('date') String sortBy,
    @Default(true) bool sortDescending,
  }) = _OrderFilterParams;
}

// Провайдер фильтров заказов
final orderFilterProvider = StateProvider<OrderFilterParams>((ref) {
  // По умолчанию фильтруем по текущей неделе
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  
  return OrderFilterParams(
    startDate: startOfWeek,
    endDate: now,
    sortBy: 'date',
    sortDescending: true,
  );
});

// Провайдер отфильтрованных заказов
final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final allOrders = ref.watch(ordersProvider).valueOrNull ?? [];
  final filterParams = ref.watch(orderFilterProvider);
  
  return allOrders.where((order) {
    // Фильтрация по дате
    if (filterParams.startDate != null && 
        order.date.isBefore(filterParams.startDate!)) {
      return false;
    }
    
    if (filterParams.endDate != null && 
        order.date.isAfter(filterParams.endDate!.add(Duration(days: 1)))) {
      return false;
    }
    
    // Фильтрация по статусу
    if (filterParams.status != null && 
        order.status != filterParams.status) {
      return false;
    }
    
    // Фильтрация по тексту поиска
    if (filterParams.searchText != null && 
        filterParams.searchText!.isNotEmpty) {
      final searchText = filterParams.searchText!.toLowerCase();
      return order.id.toLowerCase().contains(searchText) || 
             order.customerName.toLowerCase().contains(searchText);
    }
    
    return true;
  }).toList()
    // Сортировка результатов
    ..sort((a, b) {
      final aValue = _getSortValue(a, filterParams.sortBy);
      final bValue = _getSortValue(b, filterParams.sortBy);
      int result;
      
      if (aValue is String && bValue is String) {
        result = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        result = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        result = aValue.compareTo(bValue);
      } else {
        result = 0;
      }
      
      // Применяем направление сортировки
      return filterParams.sortDescending ? -result : result;
    });
});

// Вспомогательная функция для получения значения для сортировки
dynamic _getSortValue(Order order, String sortBy) {
  switch (sortBy) {
    case 'date':
      return order.date;
    case 'id':
      return order.id;
    case 'status':
      return order.status;
    case 'price':
      return order.totalPrice;
    default:
      return order.date;
  }
}
```

## Управление сложными формами (CL: 80%)

Для управления сложными формами рекомендуется использовать `StateNotifier` вместе с неизменяемыми моделями состояния:

```dart
// providers/invoice_form_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/invoice_item.dart';

part 'invoice_form_provider.freezed.dart';

// Модель состояния формы накладной
@freezed
class InvoiceFormState with _$InvoiceFormState {
  const factory InvoiceFormState({
    // Номер накладной
    @Default('') String number,
    // Дата накладной
    required DateTime date,
    // Получатель
    @Default('') String recipient,
    // Адрес
    @Default('') String address,
    // Элементы накладной
    @Default([]) List<InvoiceItem> items,
    // Флаги валидации
    @Default(false) bool isNumberValid,
    @Default(false) bool isRecipientValid,
    @Default(false) bool isAddressValid,
    @Default(false) bool areItemsValid,
    // Общий флаг валидности формы
    @Default(false) bool isValid,
  }) = _InvoiceFormState;
}

// Notifier для управления формой накладной
class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  InvoiceFormNotifier() 
      : super(InvoiceFormState(date: DateTime.now())) {
    // Начальная валидация
    _validateForm();
  }
  
  // Обновление номера накладной
  void updateNumber(String number) {
    state = state.copyWith(number: number);
    _validateForm();
  }
  
  // Обновление даты накладной
  void updateDate(DateTime date) {
    state = state.copyWith(date: date);
    _validateForm();
  }
  
  // Обновление получателя
  void updateRecipient(String recipient) {
    state = state.copyWith(recipient: recipient);
    _validateForm();
  }
  
  // Обновление адреса
  void updateAddress(String address) {
    state = state.copyWith(address: address);
    _validateForm();
  }
  
  // Добавление элемента
  void addItem(InvoiceItem item) {
    state = state.copyWith(items: [...state.items, item]);
    _validateForm();
  }
  
  // Обновление элемента
  void updateItem(int index, InvoiceItem updatedItem) {
    if (index < 0 || index >= state.items.length) return;
    
    final newItems = [...state.items];
    newItems[index] = updatedItem;
    
    state = state.copyWith(items: newItems);
    _validateForm();
  }
  
  // Удаление элемента
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    
    final newItems = [...state.items];
    newItems.removeAt(index);
    
    state = state.copyWith(items: newItems);
    _validateForm();
  }
  
  // Очистка формы
  void reset() {
    state = InvoiceFormState(date: DateTime.now());
    _validateForm();
  }
  
  // Валидация формы
  void _validateForm() {
    final isNumberValid = state.number.isNotEmpty;
    final isRecipientValid = state.recipient.isNotEmpty;
    final isAddressValid = state.address.isNotEmpty;
    final areItemsValid = state.items.isNotEmpty && 
                         state.items.every((item) => 
                            item.name.isNotEmpty && 
                            item.quantity > 0);
    
    // Обновляем состояние с результатами валидации
    state = state.copyWith(
      isNumberValid: isNumberValid,
      isRecipientValid: isRecipientValid,
      isAddressValid: isAddressValid,
      areItemsValid: areItemsValid,
      isValid: isNumberValid && isRecipientValid && 
               isAddressValid && areItemsValid,
    );
  }
}

// Провайдер формы накладной
final invoiceFormProvider = StateNotifierProvider<InvoiceFormNotifier, InvoiceFormState>((ref) {
  return InvoiceFormNotifier();
});
```

## Использование в UI

### ConsumerWidget (CL: 85%)

Рекомендуется использовать `ConsumerWidget` для доступа к провайдерам:

```dart
// ui/screens/warehouse_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/warehouse_providers.dart';
import '../models/warehouse_cell.dart';

class WarehouseScreen extends ConsumerWidget {
  const WarehouseScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем асинхронные данные о ячейках склада
    final warehouseCellsAsync = ref.watch(warehouseCellsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(warehouseCellsProvider),
          ),
        ],
      ),
      body: warehouseCellsAsync.when(
        data: (cells) => _buildCellsGrid(cells),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Ошибка загрузки данных: $error'),
        ),
      ),
    );
  }
  
  Widget _buildCellsGrid(List<WarehouseCell> cells) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final cell = cells[index];
        return _buildCellItem(cell);
      },
    );
  }
  
  Widget _buildCellItem(WarehouseCell cell) {
    // Определяем цвет в зависимости от заполненности
    final fillPercentage = cell.fillPercentage;
    Color cellColor;
    
    if (fillPercentage < 30) {
      cellColor = Colors.green;
    } else if (fillPercentage < 70) {
      cellColor = Colors.orange;
    } else {
      cellColor = Colors.red;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: cellColor.withOpacity(0.2),
        border: Border.all(color: cellColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cell.id,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${fillPercentage.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
```

### Consumer (CL: 85%)

Для оптимизации перестроений виджетов рекомендуется использовать `Consumer`:

```dart
// ui/screens/task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
      ),
      body: Column(
        children: [
          // Этот виджет не будет перестраиваться при изменении задач
          const TaskHeader(),
          
          // Этот виджет будет перестраиваться только при изменении задач
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final tasksAsync = ref.watch(activeTasksProvider);
                
                return tasksAsync.when(
                  data: (tasks) => ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Text(task.status),
                        onTap: () {
                          // Переход к деталям задачи
                        },
                      );
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskHeader extends StatelessWidget {
  const TaskHeader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: const Text(
        'Список активных задач',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

## Мониторинг изменений состояния (CL: 75%)

Для отладки приложения рекомендуется добавить логирование изменений состояния:

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

// Провайдер-наблюдатель
class LoggingProviderObserver extends ProviderObserver {
  final Logger _logger = Logger('Riverpod');

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _logger.fine(
      '[${provider.name ?? provider.runtimeType}] значение: $newValue',
    );
  }

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    _logger.fine(
      '[${provider.name ?? provider.runtimeType}] добавлен: $value',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    _logger.fine(
      '[${provider.name ?? provider.runtimeType}] удален',
    );
  }
}

void main() {
  // Настройка логирования
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Запуск приложения с логированием
  runApp(
    ProviderScope(
      observers: [LoggingProviderObserver()],
      child: const MyApp(),
    ),
  );
}
```

## Советы по производительности (CL: 80%)

### Оптимизация передачи данных

```dart
// providers/optimized_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Вместо того, чтобы передавать весь объект
final expensiveObjectProvider = Provider<ExpensiveObject>((ref) {
  return ExpensiveObject();
});

// Лучше передавать только нужные данные
final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.name ?? '';
});

final userAvatarProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.avatarUrl ?? '';
});
```

### Использование select для точечного отслеживания

```dart
// ui/widgets/user_greeting.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';

class UserGreeting extends ConsumerWidget {
  const UserGreeting({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Используем select чтобы следить только за именем, а не за всем объектом
    final userName = ref.watch(
      currentUserProvider.select((user) => user?.name ?? 'Гость')
    );
    
    return Text('Привет, $userName!');
  }
}
```

## Заключение

Выбор Riverpod в качестве основного решения для управления состоянием обеспечивает надежную, хорошо тестируемую и масштабируемую архитектуру для приложения WB Assistant. Такой подход позволяет эффективно обрабатывать как простые, так и сложные потоки данных, с поддержкой как синхронных, так и асинхронных операций.

При работе с состоянием следует придерживаться следующих принципов:
1. Разделение состояния приложения и пользовательского интерфейса
2. Использование неизменяемых (immutable) структур данных
3. Централизованное управление состоянием для предсказуемости
4. Кэширование данных для оптимальной производительности
5. Точечное обновление UI для минимизации перестроений

Такой подход обеспечит создание надежного и отзывчивого приложения, способного эффективно работать как в онлайн, так и в офлайн режиме, что критически важно для складского приложения. 