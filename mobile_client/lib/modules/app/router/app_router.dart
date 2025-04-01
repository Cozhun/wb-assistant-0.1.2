import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../orders/screens/scanner_screen.dart';
import '../../orders/screens/supply_list_screen.dart';
import '../../orders/screens/supply_details_screen.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../orders/screens/order_details_screen.dart';
import '../../orders/screens/order_labels_screen.dart';
import '../../orders/screens/order_packing_screen.dart';
import '../../inventory/screens/inventory_session_screen.dart';
import '../../inventory/screens/inventory_item_screen.dart';
import '../../warehouse/screens/warehouse_visualization_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/login_screen.dart';
import '../../shift/screens/shift_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../home/screens/splash_screen.dart';
import '../../../ui/common/screens/adaptive_ui_demo.dart';

/// Маршруты приложения
class AppRoutes {
  static const String home = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String shift = '/shift';
  static const String scanner = '/scanner';
  static const String suppliesList = '/supplies';
  static const String supplyDetails = '/supplies/:supplyId';
  static const String ordersList = '/orders';
  static const String orderDetails = '/orders/:orderId';
  static const String orderLabels = '/orders/:orderId/labels';
  static const String orderPacking = '/orders/:orderId/packing';
  static const String inventorySession = '/inventory/session';
  static const String inventoryItem = '/inventory/session/:sessionId/item/:itemId';
  static const String warehouseVisualization = '/warehouse';
  static const String adaptiveUiDemo = '/adaptive-ui-demo';
}

/// Глобальный ключ для навигатора
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Построение маршрутов приложения
List<RouteBase> getAppRoutes() {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.shift,
      builder: (context, state) => const ShiftScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) {
        final orderId = state.queryParameters['orderId'];
        final sessionId = state.queryParameters['sessionId'];
        final itemId = state.queryParameters['itemId'];
        return ScannerScreen(
          orderId: orderId,
          sessionId: sessionId,
          itemId: itemId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.suppliesList,
      builder: (context, state) => const SupplyListScreen(),
    ),
    GoRoute(
      path: AppRoutes.supplyDetails,
      builder: (context, state) {
        final supplyId = state.pathParameters['supplyId'] ?? '';
        return SupplyDetailsScreen(supplyId: supplyId);
      },
    ),
    GoRoute(
      path: AppRoutes.ordersList,
      builder: (context, state) => const OrderListScreen(),
    ),
    GoRoute(
      path: AppRoutes.orderDetails,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final supplyId = state.queryParameters['supplyId'];
        return OrderDetailsScreen(
          orderId: orderId, 
          supplyId: supplyId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.orderLabels,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderLabelsScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: AppRoutes.orderPacking,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final supplyId = state.queryParameters['supplyId'];
        return OrderPackingScreen(
          orderId: orderId,
          supplyId: supplyId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.inventorySession,
      builder: (context, state) => const InventorySessionScreen(),
    ),
    GoRoute(
      path: AppRoutes.inventoryItem,
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? '';
        final itemId = state.pathParameters['itemId'] ?? '';
        return InventoryItemScreen(
          sessionId: sessionId,
          itemId: itemId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.warehouseVisualization,
      builder: (context, state) => const WarehouseVisualizationScreen(),
    ),
    GoRoute(
      path: AppRoutes.adaptiveUiDemo,
      builder: (context, state) => const AdaptiveUiDemo(),
    ),
  ];
}

/// Построение роутера приложения
GoRouter getAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: getAppRoutes(),
    redirect: (BuildContext context, GoRouterState state) {
      final authService = AuthService();
      final bool isLoggedIn = authService.isLoggedIn;
      
      // Проверяем, авторизован ли пользователь
      final bool isGoingToLogin = state.matchedLocation == AppRoutes.login;
      final bool isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      
      // Если пользователь не авторизован и не на экране авторизации,
      // перенаправляем на экран авторизации
      if (!isLoggedIn && !isGoingToLogin && !isGoingToSplash) {
        return AppRoutes.login;
      }
      
      // Если пользователь авторизован и на экране авторизации,
      // перенаправляем на главный экран
      if (isLoggedIn && isGoingToLogin) {
        return AppRoutes.home;
      }
      
      // Оставляем текущий маршрут
      return null;
    },
  );
} 