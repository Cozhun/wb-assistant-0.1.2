# Архитектура и управление состоянием

## Обзор

Управление состоянием является ключевым аспектом разработки Flutter-приложений, особенно для таких сложных бизнес-приложений, как WB Assistant. В данном документе описаны подходы к управлению состоянием, выбор инструментов и рекомендуемые практики.

## Выбор решения для управления состоянием (CL: 95%)

После анализа доступных вариантов, для проекта WB Assistant выбрано решение на основе **Riverpod** в сочетании с паттерном **Repository** и элементами **MVC+S** (Model-View-Controller + Service).

### Преимущества Riverpod:

1. **Предсказуемость и тестируемость** — строгая типизация и декларативный подход
2. **Поддержка асинхронных операций** — встроенные `FutureProvider` и `StreamProvider`
3. **Независимость от контекста** — доступ к состоянию без `BuildContext`
4. **Поддержка DI** — естественное внедрение зависимостей
5. **Модульность** — провайдеры могут быть легко переиспользованы
6. **Удобство отладки** — инструменты для инспектирования состояния

### Сравнение с альтернативами:

| Решение | Преимущества | Недостатки | Рекомендация |
|---------|--------------|------------|--------------|
| Riverpod | Предсказуемость, тестируемость, DI | Кривая обучения | **Выбрано для проекта (CL: 95%)** |
| BLoC/Cubit | Структурированный подход, разделение логики | Многословность | Хорошо подходит для больших приложений |
| Provider | Простота, интеграция с Flutter | Ограниченная функциональность | Подходит для небольших приложений |
| GetX | Простота использования, маршрутизация | Магический подход, сложная отладка | Не рекомендуется для сложных приложений |
| Redux | Предсказуемый поток данных | Избыточность кода | Хорошо для сложной бизнес-логики |
| MobX | Реактивное программирование | Сложности с отладкой | Средняя сложность интеграции |

## Структура управления состоянием (CL: 90%)

### Слоистая архитектура

```
lib/
 ├── domain/                 # Бизнес-сущности и логика
 ├── data/                   # Источники данных и репозитории
 ├── application/            # Состояние приложения и бизнес-логика
 └── presentation/           # UI и взаимодействие с пользователем
```

### Основные компоненты

1. **Провайдеры** — основа системы управления состоянием
2. **Репозитории** — доступ к данным из различных источников
3. **Сервисы** — бизнес-логика, не привязанная к UI
4. **Нотифайеры** — обновление состояния и реакция на события

## Определение провайдеров (CL: 95%)

```dart
// Провайдер для репозитория
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(remoteDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

// Провайдер состояния
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider)
  );
});

// Провайдер текущего пользователя
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});
```

## Определение состояний (CL: 90%)

Для определения неизменяемых состояний рекомендуется использовать пакет `freezed`:

```dart
// Состояния аутентификации
@freezed
class AuthState with _$AuthState {
  // Начальное состояние
  const factory AuthState.initial() = _Initial;
  
  // Состояние загрузки
  const factory AuthState.loading() = _Loading;
  
  // Аутентифицированное состояние
  const factory AuthState.authenticated(User user) = _Authenticated;
  
  // Неаутентифицированное состояние
  const factory AuthState.unauthenticated() = _Unauthenticated;
  
  // Состояние ошибки
  const factory AuthState.error(String message) = _Error;
}
```

## Управление состоянием с StateNotifier (CL: 95%)

```dart
// Управление состоянием аутентификации
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  
  AuthNotifier({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    _checkCurrentSession();
  }
  
  // Проверка текущей сессии
  Future<void> _checkCurrentSession() async {
    state = const AuthState.loading();
    final result = await _authRepository.checkCurrentSession();
    result.fold(
      (failure) => state = const AuthState.unauthenticated(),
      (user) => state = AuthState.authenticated(user),
    );
  }
  
  // Вход в систему
  Future<void> signIn(String login, String password) async {
    state = const AuthState.loading();
    final result = await _authRepository.signIn(login, password);
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }
  
  // Выход из системы
  Future<void> signOut() async {
    state = const AuthState.loading();
    await _authRepository.signOut();
    state = const AuthState.unauthenticated();
  }
}
```

## Управление асинхронными данными (CL: 90%)

### FutureProvider для запросов к серверу

```dart
// Получение списка поставок
final shipmentsProvider = FutureProvider.autoDispose<List<Shipment>>((ref) async {
  final repository = ref.watch(shipmentRepositoryProvider);
  return repository.getShipments();
});
```

### StreamProvider для реального времени

```dart
// Получение обновлений заказов в реальном времени
final ordersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrdersStream();
});
```

## Кэширование данных (CL: 85%)

Для оптимизации производительности и поддержки оффлайн-режима важно реализовать систему кэширования:

```dart
// Провайдер с поддержкой кэша
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  
  // Пытаемся загрузить из кэша сначала
  final cachedProducts = await repository.getCachedProducts();
  if (cachedProducts.isNotEmpty) {
    // Возвращаем кэшированные данные сразу
    ref.keepAlive();
    
    // Асинхронно обновляем из сети, если доступна
    if (await ref.watch(networkInfoProvider).isConnected) {
      repository.refreshProducts().then((newProducts) {
        // Инвалидируем провайдер при получении новых данных
        ref.invalidateSelf();
      });
    }
    
    return cachedProducts;
  }
  
  // Если кэш пуст, загружаем из сети
  return repository.getProducts();
});
```

## Управление фильтрами и параметрами поиска (CL: 85%)

```dart
// Модель параметров фильтра
@freezed
class OrderFilterParams with _$OrderFilterParams {
  const factory OrderFilterParams({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    OrderStatus? status,
    bool? isPriority,
  }) = _OrderFilterParams;
}

// Провайдер параметров фильтра
final orderFilterParamsProvider = StateProvider<OrderFilterParams>((ref) {
  return const OrderFilterParams();
});

// Провайдер отфильтрованных заказов
final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final filters = ref.watch(orderFilterParamsProvider);
  final orders = ref.watch(ordersProvider).asData?.value ?? [];
  
  return orders.where((order) {
    // Применение фильтров
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      if (!order.number.contains(filters.searchQuery!)) {
        return false;
      }
    }
    
    if (filters.status != null && order.status != filters.status) {
      return false;
    }
    
    if (filters.isPriority != null && order.isPriority != filters.isPriority) {
      return false;
    }
    
    if (filters.startDate != null && order.createdAt.isBefore(filters.startDate!)) {
      return false;
    }
    
    if (filters.endDate != null && order.createdAt.isAfter(filters.endDate!)) {
      return false;
    }
    
    return true;
  }).toList();
});
```

## Управление формами (CL: 90%)

Для сложных форм рекомендуется использовать комбинацию `StateNotifier` и неизменяемых моделей:

```dart
// Состояние формы накладной
@freezed
class InvoiceFormState with _$InvoiceFormState {
  const factory InvoiceFormState({
    required String invoiceNumber,
    required DateTime date,
    required List<InvoiceItem> items,
    String? comment,
    @Default(false) bool isValid,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _InvoiceFormState;

  factory InvoiceFormState.initial() => InvoiceFormState(
    invoiceNumber: '',
    date: DateTime.now(),
    items: [],
  );
}

// Управление состоянием формы
class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  InvoiceFormNotifier() : super(InvoiceFormState.initial());

  void setInvoiceNumber(String number) {
    state = state.copyWith(
      invoiceNumber: number,
      isValid: _validateForm(number, state.items),
    );
  }

  void addItem(InvoiceItem item) {
    final updatedItems = [...state.items, item];
    state = state.copyWith(
      items: updatedItems,
      isValid: _validateForm(state.invoiceNumber, updatedItems),
    );
  }

  void removeItem(String itemId) {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(
      items: updatedItems,
      isValid: _validateForm(state.invoiceNumber, updatedItems),
    );
  }

  bool _validateForm(String invoiceNumber, List<InvoiceItem> items) {
    return invoiceNumber.isNotEmpty && items.isNotEmpty;
  }

  Future<void> submitForm() async {
    if (!state.isValid) return;

    state = state.copyWith(isSubmitting: true);
    try {
      // Логика отправки формы...
      // ...
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
    }
  }
}
```

## Потребление состояния в UI (CL: 95%)

### Consumer для отслеживания изменений

```dart
// Чтение значения провайдера в виджете
class WarehouseScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Используем AsyncValue для отображения различных состояний
    final warehouseCells = ref.watch(warehouseCellsProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Склад')),
      body: warehouseCells.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
        data: (cells) => WarehouseGrid(cells: cells),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.refresh(warehouseCellsProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

### ConsumerStatefulWidget для сохранения состояния

```dart
// Управление состоянием виджета с доступом к провайдерам
class OrderEditScreen extends ConsumerStatefulWidget {
  final String orderId;
  
  const OrderEditScreen({Key? key, required this.orderId}) : super(key: key);
  
  @override
  _OrderEditScreenState createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends ConsumerState<OrderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    // Доступ к провайдерам в initState
    Future.microtask(() {
      ref.read(orderNotifierProvider.notifier).loadOrder(widget.orderId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Отслеживание состояния заказа
    final orderState = ref.watch(orderNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Редактирование заказа')),
      body: orderState.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (order) => OrderForm(
          order: order,
          formKey: _formKey,
          onSubmit: () {
            if (_formKey.currentState?.validate() ?? false) {
              ref.read(orderNotifierProvider.notifier).saveOrder();
            }
          },
        ),
        error: (message) => Center(child: Text('Ошибка: $message')),
      ),
    );
  }
}
```

## Модульные тесты состояния (CL: 90%)

```dart
void main() {
  late AuthNotifier authNotifier;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authNotifier = AuthNotifier(authRepository: mockAuthRepository);
  });

  test('initial state is AuthState.initial', () {
    expect(authNotifier.debugState, equals(const AuthState.initial()));
  });

  group('signIn', () {
    test('emits [loading, authenticated] when successful', () async {
      // Arrange
      when(mockAuthRepository.signIn(any, any))
          .thenAnswer((_) async => Right(tUser));

      // Act
      await authNotifier.signIn('test@test.com', 'password');

      // Assert
      expect(
        authNotifier.debugState,
        equals(AuthState.authenticated(tUser)),
      );
    });

    test('emits [loading, error] when unsuccessful', () async {
      // Arrange
      when(mockAuthRepository.signIn(any, any))
          .thenAnswer((_) async => Left(ServerFailure('Invalid credentials')));

      // Act
      await authNotifier.signIn('test@test.com', 'password');

      // Assert
      expect(
        authNotifier.debugState,
        equals(const AuthState.error('Invalid credentials')),
      );
    });
  });
}
```

## Управление глобальным состоянием (CL: 85%)

Для управления глобальным состоянием и состоянием, которое должно сохраняться между экранами, рекомендуется:

1. **ProviderScope** — определяет область видимости провайдеров
2. **ProviderContainer** — хранит состояние всех провайдеров
3. **ref.keepAlive()** — предотвращает переинициализацию состояния

```dart
void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Переопределение провайдеров для тестирования
        // или с фиксированными начальными значениями
      ],
      child: MyApp(),
    ),
  );
}
```

## Рекомендации по управлению состоянием (CL: 90%)

1. **Делайте состояние неизменяемым** — используйте `freezed` или `immutable` классы
2. **Разделяйте доступ к данным и логику** — репозитории отвечают за данные, нотифайеры за логику
3. **Минимизируйте перестроение виджетов** — выбирайте с помощью `select` только необходимые части состояния
4. **Кэшируйте асинхронное состояние** — для улучшения UX и поддержки оффлайн-режима
5. **Поддерживайте одно направление потока данных** — сверху вниз
6. **Используйте DI для тестирования** — заменяйте настоящие репозитории на моки
7. **Делайте явные зависимости** — указывайте все зависимости в конструкторах
8. **Отделяйте UI от бизнес-логики** — UI должен только отображать состояние и вызывать действия

## Заключение

Управление состоянием в WB Assistant построено на современных подходах и инструментах, обеспечивающих предсказуемость, тестируемость и масштабируемость. Использование Riverpod позволяет создать надежную архитектуру, которая обеспечивает стабильную работу приложения на всех целевых платформах.

Система спроектирована с учетом специфических требований проекта: сложная бизнес-логика, асинхронные операции, кэширование данных, работа в оффлайн-режиме и кросс-платформенная совместимость. 