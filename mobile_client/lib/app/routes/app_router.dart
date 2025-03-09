import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/screens/login_screen.dart';
import '../../modules/orders/screens/order_list_screen.dart';
import '../../modules/orders/screens/order_details_screen.dart';
import '../../modules/orders/screens/scanner_screen.dart';

/// Конфигурация маршрутизации приложения
final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Экран авторизации
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Основные экраны приложения
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        // Список заказов
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderListScreen(),
          routes: [
            // Детали заказа
            GoRoute(
              path: 'details/:orderId',
              builder: (context, state) {
                final orderId = state.pathParameters['orderId'] ?? '';
                return OrderDetailsScreen(orderId: orderId);
              },
            ),
          ],
        ),
        
        // Экран сканера
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen(),
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

/// Шаблон для нижней навигации
class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Сканер',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/orders')) {
      return 0;
    }
    if (location.startsWith('/scanner')) {
      return 1;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/orders');
        break;
      case 1:
        context.go('/scanner');
        break;
    }
  }
} 