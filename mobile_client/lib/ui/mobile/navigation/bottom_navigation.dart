import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/navigation/navigation_item.dart';

/// Компонент с нижней навигацией для мобильного клиента
class CustomBottomNavigationBar extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            final int index = entry.key;
            final NavigationItem item = entry.value;
            final bool isSelected = index == selectedIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onItemSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).unselectedWidgetColor,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).unselectedWidgetColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Шаблон для добавления нижней навигации в приложение
class ScaffoldWithBottomNavBar extends StatefulWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
  });

  @override
  _ScaffoldWithBottomNavBarState createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends State<ScaffoldWithBottomNavBar> {
  int _selectedIndex = 0;

  static final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      label: 'Заказы',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
    ),
    const NavigationItem(
      label: 'Сканер',
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
    ),
    const NavigationItem(
      label: 'Запросы',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
    ),
    const NavigationItem(
      label: 'Профиль',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/orders');
        break;
      case 1:
        context.go('/scanner');
        break;
      case 2:
        context.go('/requests');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomBottomNavigationBar(
        items: _navigationItems,
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
} 