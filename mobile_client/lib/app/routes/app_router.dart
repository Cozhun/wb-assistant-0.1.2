import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../modules/orders/screens/order_list_screen.dart';
import '../../modules/orders/screens/order_details_screen.dart';
import '../../modules/orders/screens/order_labels_screen.dart';
import '../../modules/orders/screens/scanner_screen.dart';
import '../../modules/orders/screens/supply_list_screen.dart';
import '../../modules/orders/screens/supply_details_screen.dart';
import '../../modules/requests/screens/request_list_screen.dart';
import '../../modules/requests/screens/request_details_screen.dart';
import '../../modules/profile/screens/profile_screen.dart';
import '../../modules/shift/screens/shift_screen.dart';
import '../../modules/inventory/screens/inventory_list_screen.dart';
import '../../modules/inventory/screens/inventory_session_screen.dart';
import '../../modules/inventory/screens/warehouse_visualization_screen.dart';
import '../../ui/common/widgets/adaptive_ui_demo.dart';
import '../../ui/common/widgets/theme_demo_screen.dart';
// import '../../ui/mobile/navigation/bottom_navigation.dart';

/// Класс маршрутизатора приложения
class AppRouter {
  // Статический экземпляр для доступа к навигатору
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static GlobalKey<NavigatorState> get navigatorKey => _rootNavigatorKey;

  // Статический метод для навигации, используемый в сервисах
  static void navigateTo(String location) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      goRouter.go(location);
    }
  }
  
  // Getter для доступа к маршрутизатору
  GoRouter get router => goRouter;

  // Определение маршрутизатора
  static final goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      // Экран авторизации
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Демонстрация адаптивного UI
      GoRoute(
        path: '/adaptive-ui-demo',
        builder: (context, state) => const AdaptiveUiDemo(),
      ),
      
      // Демонстрация темы
      GoRoute(
        path: '/theme-demo',
        builder: (context, state) => const ThemeDemoScreen(),
      ),
      
      // Основные экраны приложения
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(
            location: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          // Экран смены (начальный экран после входа)
          GoRoute(
            path: '/shift',
            builder: (context, state) => const ShiftScreen(),
          ),
          
          // Список заказов
          GoRoute(
            path: '/orders',
            builder: (context, state) {
              final fromClosedSupplies = state.uri.queryParameters['fromClosedSupplies'] == 'true';
              return OrderListScreen(fromClosedSupplies: fromClosedSupplies);
            },
            routes: [
              // Детали заказа
              GoRoute(
                path: 'details/:orderId',
                builder: (context, state) {
                  final orderId = state.pathParameters['orderId'] ?? '';
                  return OrderDetailsScreen(orderId: orderId);
                },
                routes: [
                  // Экран для печати ярлыков и этикеток
                  GoRoute(
                    path: 'labels',
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId'] ?? '';
                      return OrderLabelsScreen(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),
          
          // Список поставок
          GoRoute(
            path: '/supplies',
            builder: (context, state) => const SupplyListScreen(),
            routes: [
              // Только просмотр деталей поставки (без создания/редактирования)
              GoRoute(
                path: ':supplyId',
                builder: (context, state) {
                  final supplyId = state.pathParameters['supplyId'] ?? '';
                  return SupplyDetailsScreen(supplyId: supplyId);
                },
              ),
              // Маршрут для заказов из закрытых поставок
              GoRoute(
                path: 'closed-orders',
                builder: (context, state) => const OrderListScreen(fromClosedSupplies: true),
              ),
            ],
          ),
          
          // Экран сканера
          GoRoute(
            path: '/scanner',
            builder: (context, state) {
              // Получаем параметры из extra или queryParams
              final extra = state.extra as Map<String, dynamic>?;
              
              // Приоритет отдается параметрам из URL, если они существуют
              final supplyId = state.uri.queryParameters['supplyId'] ?? extra?['supplyId'] as String?;
              
              // Параметры для обратного вызова по-прежнему через extra
              final onScanComplete = extra?['onScanComplete'] as VoidCallback?;
              
              // Параметры для режима инвентаризации
              final inventoryMode = state.uri.queryParameters['inventoryMode'] == 'true' || 
                  (extra != null && extra.containsKey('inventoryMode') && extra['inventoryMode'] == true);
              final sessionId = state.uri.queryParameters['sessionId'] ?? 
                  (extra != null ? extra['sessionId'] as String? : null);
              final inventoryItem = extra?['inventoryItem'];
              
              return ScannerScreen(
                supplyId: supplyId,
                onScanComplete: onScanComplete,
                inventoryMode: inventoryMode,
                inventoryItem: inventoryItem,
                inventorySessionId: sessionId,
              );
            },
          ),
          
          // Список запросов
          GoRoute(
            path: '/requests',
            builder: (context, state) => const RequestListScreen(),
            routes: [
              // Детали запроса
              GoRoute(
                path: ':requestId',
                builder: (context, state) {
                  final requestId = int.tryParse(state.pathParameters['requestId'] ?? '') ?? 0;
                  return RequestDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
          
          // Экран инвентаризации
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryListScreen(),
            routes: [
              // Детали сеанса инвентаризации
              GoRoute(
                path: ':sessionId',
                builder: (context, state) {
                  final sessionId = state.pathParameters['sessionId'] ?? '';
                  final extra = state.extra as Map<String, dynamic>?;
                  final cell = extra?['cell'];
                  final onComplete = extra?['onComplete'] as VoidCallback?;
                  
                  return InventorySessionScreen(
                    sessionId: sessionId,
                    cell: cell,
                    onComplete: onComplete,
                  );
                },
              ),
              // Визуализация склада
              GoRoute(
                path: 'warehouse-visualization',
                builder: (context, state) => const WarehouseVisualizationScreen(),
              ),
            ],
          ),
          
          // Экран профиля
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Text('Страница не найдена: ${state.uri.path}'),
      ),
    ),
  );
}

/// Шаблон для нижней навигации
class ScaffoldWithBottomNavBar extends StatelessWidget {
  // Местоположение для определения выбранного пункта меню
  final String location;
  final Widget child;

  const ScaffoldWithBottomNavBar({
    Key? key,
    required this.location,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(location),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Смена',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Поставки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Сканер',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  // Вычисление индекса выбранного пункта по текущему маршруту
  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/shift')) {
      return 0;
    }
    if (location.startsWith('/supplies')) {
      return 1;
    }
    if (location.startsWith('/scanner')) {
      return 2;
    }
    if (location.startsWith('/requests')) {
      return 3;
    }
    if (location.startsWith('/profile')) {
      return 4;
    }
    return 0;
  }

  // Переход по нажатию на элемент нижней навигации
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/shift');
        break;
      case 1:
        GoRouter.of(context).go('/supplies');
        break;
      case 2:
        GoRouter.of(context).go('/scanner');
        break;
      case 3:
        GoRouter.of(context).go('/requests');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
} 