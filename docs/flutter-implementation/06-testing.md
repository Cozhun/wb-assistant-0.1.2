# Тестирование Flutter-приложения

## Обзор

В данном документе описаны подходы к тестированию кросс-платформенного Flutter-приложения WB Assistant. Эффективное тестирование является критически важным для обеспечения стабильности и надежности приложения, особенно учитывая сложную бизнес-логику складского учета и наличие кросс-платформенных компонентов.

## Уровни тестирования (CL: 95%)

В проекте WB Assistant рекомендуется использовать комплексный подход к тестированию, включающий следующие уровни:

1. **Модульные тесты (Unit Tests)** - тестирование отдельных функций, классов и методов в изоляции.
2. **Тесты виджетов (Widget Tests)** - тестирование отдельных виджетов и их взаимодействия.
3. **Интеграционные тесты (Integration Tests)** - тестирование взаимодействия нескольких компонентов приложения.
4. **UI-тесты (End-to-End Tests)** - тестирование приложения как конечный пользователь.

**Источники**:
- [Официальная документация Flutter по тестированию](https://flutter.dev/docs/testing)
- [Testing Flutter Apps](https://flutter.dev/docs/cookbook/testing)

## Структура тестов

Рекомендуемая структура директорий для тестов:

```
project/
├── lib/
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   ├── services/
│   └── ui/
└── test/
    ├── unit/
    │   ├── models/
    │   ├── providers/
    │   ├── repositories/
    │   └── services/
    ├── widget/
    │   └── ui/
    └── integration/
```

## Модульные тесты (Unit Tests) (CL: 90%)

### Настройка и зависимости

В файле `pubspec.yaml` необходимо добавить следующие зависимости для тестирования:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.1
  build_runner: ^2.4.4
  mocktail: ^1.0.0
```

### Тестирование моделей данных

```dart
// test/unit/models/warehouse_cell_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wb_assistant/models/warehouse_cell.dart';

void main() {
  group('WarehouseCell', () {
    test('should correctly calculate fillPercentage', () {
      // Arrange
      final cell = WarehouseCell(
        id: 'A1',
        capacity: 100,
        occupied: 30,
      );
      
      // Act
      final percentage = cell.fillPercentage;
      
      // Assert
      expect(percentage, 30);
    });
    
    test('should correctly determine if cell is full', () {
      // Arrange
      final fullCell = WarehouseCell(
        id: 'A1',
        capacity: 100,
        occupied: 100,
      );
      
      final notFullCell = WarehouseCell(
        id: 'A2',
        capacity: 100,
        occupied: 99,
      );
      
      // Assert
      expect(fullCell.isFull, true);
      expect(notFullCell.isFull, false);
    });
    
    test('should correctly parse from JSON', () {
      // Arrange
      final json = {
        'id': 'A1',
        'capacity': 100,
        'occupied': 30,
        'section': 'General',
      };
      
      // Act
      final cell = WarehouseCell.fromJson(json);
      
      // Assert
      expect(cell.id, 'A1');
      expect(cell.capacity, 100);
      expect(cell.occupied, 30);
      expect(cell.section, 'General');
    });
    
    test('should correctly convert to JSON', () {
      // Arrange
      final cell = WarehouseCell(
        id: 'A1',
        capacity: 100,
        occupied: 30,
        section: 'General',
      );
      
      // Act
      final json = cell.toJson();
      
      // Assert
      expect(json['id'], 'A1');
      expect(json['capacity'], 100);
      expect(json['occupied'], 30);
      expect(json['section'], 'General');
    });
  });
}
```

### Тестирование репозиториев с использованием моков

```dart
// test/unit/repositories/warehouse_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wb_assistant/services/api_client.dart';
import 'package:wb_assistant/repositories/warehouse_repository.dart';
import 'package:wb_assistant/models/warehouse_cell.dart';

import 'warehouse_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('WarehouseRepository', () {
    late MockApiClient mockApiClient;
    late WarehouseRepository repository;
    
    setUp(() {
      mockApiClient = MockApiClient();
      repository = WarehouseRepository(apiClient: mockApiClient);
    });
    
    test('getCells should return list of cells from API', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'A1',
          'capacity': 100,
          'occupied': 30,
          'section': 'General',
        },
        {
          'id': 'A2',
          'capacity': 100,
          'occupied': 50,
          'section': 'General',
        },
      ];
      
      when(mockApiClient.get('/warehouse/cells'))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      final result = await repository.getCells();
      
      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'A1');
      expect(result[1].id, 'A2');
      verify(mockApiClient.get('/warehouse/cells')).called(1);
    });
    
    test('getCellById should return specific cell from API', () async {
      // Arrange
      final mockResponse = {
        'id': 'A1',
        'capacity': 100,
        'occupied': 30,
        'section': 'General',
      };
      
      when(mockApiClient.get('/warehouse/cells/A1'))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      final result = await repository.getCellById('A1');
      
      // Assert
      expect(result.id, 'A1');
      expect(result.capacity, 100);
      expect(result.occupied, 30);
      verify(mockApiClient.get('/warehouse/cells/A1')).called(1);
    });
    
    test('updateCell should call API with correct parameters', () async {
      // Arrange
      final cell = WarehouseCell(
        id: 'A1',
        capacity: 100,
        occupied: 50,
        section: 'General',
      );
      
      when(mockApiClient.put('/warehouse/cells/A1', any))
          .thenAnswer((_) async => {'success': true});
      
      // Act
      await repository.updateCell(cell);
      
      // Assert
      verify(mockApiClient.put('/warehouse/cells/A1', {
        'capacity': 100,
        'occupied': 50,
        'section': 'General',
      })).called(1);
    });
    
    test('getCells should handle API error', () async {
      // Arrange
      when(mockApiClient.get('/warehouse/cells'))
          .thenThrow(Exception('Network error'));
      
      // Act & Assert
      expect(() => repository.getCells(), throwsException);
    });
  });
}
```

### Тестирование Riverpod провайдеров

```dart
// test/unit/providers/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wb_assistant/providers/auth_providers.dart';
import 'package:wb_assistant/repositories/auth_repository.dart';
import 'package:wb_assistant/models/user.dart';
import 'package:wb_assistant/providers/state/auth_state.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('AuthNotifier', () {
    late MockAuthRepository mockRepository;
    late AuthNotifier authNotifier;
    
    setUp(() {
      mockRepository = MockAuthRepository();
      authNotifier = AuthNotifier(mockRepository);
    });
    
    test('initial state should be loading', () {
      expect(authNotifier.state, const AuthState.loading());
    });
    
    test('should authenticate user on successful sign in', () async {
      // Arrange
      final user = User(id: '1', name: 'Test User', role: 'admin');
      when(mockRepository.signIn(any, any))
          .thenAnswer((_) async => user);
      
      // Act
      await authNotifier.signIn('test@example.com', 'password');
      
      // Assert
      expect(authNotifier.state, AuthState.authenticated(user));
      verify(mockRepository.signIn('test@example.com', 'password')).called(1);
    });
    
    test('should set error state on sign in failure', () async {
      // Arrange
      when(mockRepository.signIn(any, any))
          .thenThrow(Exception('Invalid credentials'));
      
      // Act
      await authNotifier.signIn('test@example.com', 'wrong_password');
      
      // Assert
      expect(
        authNotifier.state,
        predicate((state) => 
          state is _Error && 
          state.message.contains('Invalid credentials')
        ),
      );
    });
    
    test('should set unauthenticated state on sign out', () async {
      // Arrange
      when(mockRepository.signOut())
          .thenAnswer((_) async => null);
      
      // Set initial authenticated state
      final user = User(id: '1', name: 'Test User', role: 'admin');
      authNotifier.state = AuthState.authenticated(user);
      
      // Act
      await authNotifier.signOut();
      
      // Assert
      expect(authNotifier.state, const AuthState.unauthenticated());
      verify(mockRepository.signOut()).called(1);
    });
  });
  
  group('AuthProviders', () {
    test('currentUserProvider should return user from authenticated state', () {
      // Arrange
      final user = User(id: '1', name: 'Test User', role: 'admin');
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(
            AuthState.authenticated(user)
          ),
        ],
      );
      
      // Act
      final result = container.read(currentUserProvider);
      
      // Assert
      expect(result, user);
      
      // Cleanup
      container.dispose();
    });
    
    test('currentUserProvider should return null for non-authenticated states', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWithValue(
            const AuthState.unauthenticated()
          ),
        ],
      );
      
      // Act
      final result = container.read(currentUserProvider);
      
      // Assert
      expect(result, null);
      
      // Cleanup
      container.dispose();
    });
  });
}
```

## Тесты виджетов (Widget Tests) (CL: 85%)

### Базовые тесты компонентов UI

```dart
// test/widget/ui/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wb_assistant/ui/screens/login_screen.dart';
import 'package:wb_assistant/providers/auth_providers.dart';
import 'package:wb_assistant/providers/state/auth_state.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthNotifier])
void main() {
  group('LoginScreen', () {
    late MockAuthNotifier mockAuthNotifier;
    
    setUp(() {
      mockAuthNotifier = MockAuthNotifier();
    });
    
    testWidgets('should display login form', (WidgetTester tester) async {
      // Arrange
      when(mockAuthNotifier.state).thenReturn(const AuthState.unauthenticated());
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Вход в систему'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Логин и пароль
      expect(find.byType(ElevatedButton), findsOneWidget); // Кнопка входа
    });
    
    testWidgets('should call signIn when form is submitted', 
        (WidgetTester tester) async {
      // Arrange
      when(mockAuthNotifier.state).thenReturn(const AuthState.unauthenticated());
      when(mockAuthNotifier.signIn(any, any)).thenAnswer((_) async {});
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Заполняем форму
      await tester.enterText(
          find.byKey(const ValueKey('login_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const ValueKey('password_field')), 'password');
      
      // Нажимаем на кнопку входа
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Assert
      verify(mockAuthNotifier.signIn('test@example.com', 'password')).called(1);
    });
    
    testWidgets('should show loading indicator while authenticating',
        (WidgetTester tester) async {
      // Arrange
      when(mockAuthNotifier.state).thenReturn(const AuthState.loading());
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should show error message when authentication fails',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Неверные учетные данные';
      when(mockAuthNotifier.state).thenReturn(const AuthState.error(errorMessage));
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWithValue(mockAuthNotifier),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      
      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
```

### Тестирование сложных виджетов с пользовательским взаимодействием

```dart
// test/widget/ui/warehouse_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wb_assistant/ui/widgets/warehouse_grid.dart';
import 'package:wb_assistant/models/warehouse_cell.dart';
import 'package:wb_assistant/providers/warehouse_providers.dart';

void main() {
  final mockCells = [
    WarehouseCell(id: 'A1', capacity: 100, occupied: 20, section: 'General'),
    WarehouseCell(id: 'A2', capacity: 100, occupied: 50, section: 'General'),
    WarehouseCell(id: 'A3', capacity: 100, occupied: 80, section: 'General'),
    WarehouseCell(id: 'B1', capacity: 100, occupied: 30, section: 'Cold'),
  ];

  group('WarehouseGrid', () {
    testWidgets('should display cells in a grid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            warehouseCellsProvider.overrideWithValue(
              AsyncValue.data(mockCells),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WarehouseGrid(),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
      expect(find.text('A3'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
      
      // Проверяем цвета ячеек
      final a1Container = tester.widget<Container>(
        find.ancestor(
          of: find.text('A1'),
          matching: find.byType(Container),
        ).first,
      );
      final a3Container = tester.widget<Container>(
        find.ancestor(
          of: find.text('A3'),
          matching: find.byType(Container),
        ).first,
      );
      
      // A1 должен быть зеленым (низкий уровень заполнения)
      expect(
        (a1Container.decoration as BoxDecoration).border!.top.color,
        Colors.green,
      );
      
      // A3 должен быть красным (высокий уровень заполнения)
      expect(
        (a3Container.decoration as BoxDecoration).border!.top.color,
        Colors.red,
      );
    });
    
    testWidgets('should show details when cell is tapped', 
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            warehouseCellsProvider.overrideWithValue(
              AsyncValue.data(mockCells),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WarehouseGrid(),
            ),
          ),
        ),
      );
      
      // Act - tap on the A2 cell
      await tester.tap(find.text('A2'));
      await tester.pumpAndSettle();
      
      // Assert - check if details dialog is shown
      expect(find.text('Информация о ячейке A2'), findsOneWidget);
      expect(find.text('Вместимость: 100'), findsOneWidget);
      expect(find.text('Занято: 50'), findsOneWidget);
      expect(find.text('Секция: General'), findsOneWidget);
    });
    
    testWidgets('should show loading indicator when data is loading',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            warehouseCellsProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WarehouseGrid(),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should show error message when data loading fails',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            warehouseCellsProvider.overrideWithValue(
              AsyncValue.error('Ошибка загрузки данных', StackTrace.empty),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WarehouseGrid(),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Ошибка загрузки данных'), findsOneWidget);
    });
  });
}
```

## Интеграционные тесты (Integration Tests) (CL: 80%)

### Настройка интеграционных тестов

В файле `pubspec.yaml` необходимо добавить:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

Создайте директорию для интеграционных тестов:

```
integration_test/
  app_test.dart
```

### Пример интеграционного теста

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wb_assistant/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('end-to-end test', () {
    testWidgets('login and navigate to warehouse screen',
        (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();
      
      // Проверяем, что мы на экране входа
      expect(find.text('Вход в систему'), findsOneWidget);
      
      // Вводим учетные данные
      await tester.enterText(
        find.byKey(const ValueKey('login_field')), 'test@example.com');
      await tester.enterText(
        find.byKey(const ValueKey('password_field')), 'password');
      
      // Нажимаем кнопку входа
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Проверяем, что мы на главном экране
      expect(find.text('Склад'), findsOneWidget);
      
      // Переходим на экран склада
      await tester.tap(find.text('Склад'));
      await tester.pumpAndSettle();
      
      // Проверяем, что на экране склада отображаются ячейки
      expect(find.byType(GridView), findsOneWidget);
      
      // Проверяем возможность взаимодействия с ячейкой
      final firstCell = find.byType(Container).first;
      await tester.tap(firstCell);
      await tester.pumpAndSettle();
      
      // Проверяем появление диалога с информацией о ячейке
      expect(find.text('Информация о ячейке'), findsOneWidget);
      
      // Закрываем диалог
      await tester.tap(find.text('Закрыть'));
      await tester.pumpAndSettle();
      
      // Выход из системы
      await tester.tap(find.byIcon(Icons.exit_to_app));
      await tester.pumpAndSettle();
      
      // Проверяем, что вернулись на экран входа
      expect(find.text('Вход в систему'), findsOneWidget);
    });
  });
}
```

## Тестирование производительности (CL: 75%)

### Настройка тестов производительности

Для измерения производительности можно использовать пакет `integration_test` совместно с метриками Flutter:

```dart
// integration_test/performance_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wb_assistant/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('measure scrolling performance', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();
      
      // Вход в систему (предполагается, что есть функция для тестового входа)
      await performLogin(tester);
      
      // Переход на экран с длинным списком (например, заказы)
      await tester.tap(find.text('Заказы'));
      await tester.pumpAndSettle();
      
      // Начало записи метрик
      await Integration.startPerformanceTracking();
      
      // Выполнение 10 прокруток для измерения производительности
      for (int i = 0; i < 10; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(); // Не ждем полной загрузки, чтобы измерить плавность
      }
      
      // Получение результатов
      final results = await Integration.stopPerformanceTracking();
      
      // Анализ и проверка результатов
      final averageFrameTime = results['averageFrameRasterizeTimeMillis'] as double;
      final jankCount = results['jankCount'] as int;
      
      // Проверяем, что время отрисовки кадра не превышает порог
      expect(averageFrameTime, lessThan(16.0)); // 60 FPS = 16.6ms/frame
      
      // Проверяем количество "заиканий" (резких задержек)
      expect(jankCount, lessThan(5));
    });
  });
}

Future<void> performLogin(WidgetTester tester) async {
  // Код входа в систему для тестов
  await tester.enterText(
    find.byKey(const ValueKey('login_field')), 'test@example.com');
  await tester.enterText(
    find.byKey(const ValueKey('password_field')), 'password');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}
```

## Тестирование доступности (Accessibility) (CL: 70%)

```dart
// test/widget/accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wb_assistant/ui/screens/login_screen.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('Login screen has correct semantic labels', 
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      
      // Act & Assert
      expect(
        tester.getSemantics(find.byKey(const ValueKey('login_field'))),
        matchesSemantics(
          label: 'Логин или email',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      
      expect(
        tester.getSemantics(find.byKey(const ValueKey('password_field'))),
        matchesSemantics(
          label: 'Пароль',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          isObscured: true,
        ),
      );
      
      expect(
        tester.getSemantics(find.byType(ElevatedButton)),
        matchesSemantics(
          label: 'Войти',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });
    
    testWidgets('Color contrast meets accessibility standards', 
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      
      // Act
      final buttonColor = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton)
      ).style?.backgroundColor?.resolve({});
      
      final buttonTextStyle = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton)
      ).style?.textStyle?.resolve({});
      
      // Assert
      // Проверка контрастности (примерная)
      // В реальном приложении лучше использовать специальную библиотеку
      expect(buttonColor, isNotNull);
      expect(buttonTextStyle, isNotNull);
      
      // Проверяем, что размер текста достаточно большой
      final textSize = buttonTextStyle?.fontSize ?? 14.0;
      expect(textSize, greaterThanOrEqualTo(14.0));
    });
  });
}
```

## Тестирование на разных платформах (CL: 85%)

### Настройка платформенно-зависимых тестов

```dart
// test/unit/platform_specific_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wb_assistant/services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MockWebStorageService extends Mock implements WebStorageService {}
class MockMobileStorageService extends Mock implements MobileStorageService {}

void main() {
  group('StorageServiceFactory', () {
    test('should create WebStorageService on web platform', () {
      // Мокаем глобальную проверку платформы
      debugDefaultTargetPlatformOverride = TargetPlatform.web;
      
      // Act
      final service = StorageServiceFactory.create();
      
      // Assert
      expect(service, isA<WebStorageService>());
      
      // Cleanup
      debugDefaultTargetPlatformOverride = null;
    });
    
    test('should create MobileStorageService on Android', () {
      // Мокаем глобальную проверку платформы
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      
      // Act
      final service = StorageServiceFactory.create();
      
      // Assert
      expect(service, isA<MobileStorageService>());
      
      // Cleanup
      debugDefaultTargetPlatformOverride = null;
    });
    
    test('should create MobileStorageService on iOS', () {
      // Мокаем глобальную проверку платформы
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      
      // Act
      final service = StorageServiceFactory.create();
      
      // Assert
      expect(service, isA<MobileStorageService>());
      
      // Cleanup
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
```

## Автоматизация тестирования и CI/CD (CL: 75%)

### Настройка GitHub Actions для автоматического запуска тестов

Файл `.github/workflows/flutter_tests.yml`:

```yaml
name: Flutter Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Flutter Tests
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Verify formatting
        run: flutter format --set-exit-if-changed .
      
      - name: Analyze project source
        run: flutter analyze
      
      - name: Run unit and widget tests
        run: flutter test
      
      - name: Build APK
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: flutter build apk
      
      - name: Upload APK
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
```

### Скрипт для локального запуска всех тестов

Файл `scripts/run_tests.sh`:

```bash
#!/bin/bash

echo "Running Flutter format check..."
flutter format --set-exit-if-changed .

echo "Running Flutter analyzer..."
flutter analyze

echo "Running unit and widget tests..."
flutter test

echo "Building app in debug mode..."
flutter build apk --debug

echo "Running integration tests..."
flutter test integration_test/app_test.dart
```

## Лучшие практики тестирования (CL: 90%)

1. **Принцип одной ответственности**: Каждый тест должен проверять только одну функциональность или сценарий.
2. **Независимость тестов**: Тесты не должны зависеть друг от друга или от порядка выполнения.
3. **Изоляция внешних зависимостей**: Используйте моки и стабы для изоляции тестируемого кода от внешних зависимостей.
4. **Тестирование всех платформ**: Убедитесь, что тесты выполняются на всех поддерживаемых платформах.
5. **Постоянное обновление тестов**: Обновляйте тесты при изменении функциональности.
6. **Покрытие кода**: Стремитесь к высокому покрытию кода тестами (минимум 80%).
7. **Тестирование граничных условий**: Включайте тесты для граничных условий и крайних случаев.
8. **Читаемые тесты**: Используйте понятные имена тестов и группировку для удобства чтения и поддержки.

## Заключение

Комплексный подход к тестированию Flutter-приложения WB Assistant, включающий модульные, виджет, интеграционные и UI-тесты, обеспечит высокую надежность и стабильность приложения. Особое внимание следует уделить тестированию кросс-платформенных аспектов, чтобы обеспечить одинаково высокое качество работы приложения на всех поддерживаемых платформах.

Внедрение автоматизации тестирования в процесс CI/CD позволит оперативно выявлять проблемы при внесении изменений в код, что в конечном итоге повысит качество продукта и снизит затраты на исправление ошибок на поздних стадиях разработки. 