import '../../modules/orders/screens/supply_list_screen.dart';
import '../../modules/orders/screens/supply_details_screen.dart';
import '../../modules/orders/screens/supply_form_screen.dart';

// В разделе определения маршрутов
// ... existing code ...
      // Маршруты для поставок
      GoRoute(
        path: '/supplies',
        name: 'supplies',
        builder: (context, state) => const SupplyListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'new-supply',
            builder: (context, state) => const SupplyFormScreen(),
          ),
          GoRoute(
            path: ':supplyId',
            name: 'supply-details',
            builder: (context, state) {
              final supplyId = state.pathParameters['supplyId']!;
              return SupplyDetailsScreen(supplyId: supplyId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-supply',
                builder: (context, state) {
                  final supplyId = state.pathParameters['supplyId']!;
                  return SupplyFormScreen(supplyId: supplyId);
                },
              ),
            ],
          ),
        ],
      ),
// ... existing code ... 