import 'package:flutter/material.dart';
import '../../common/navigation/navigation_item.dart';

class WebScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int) onNavigationItemSelected;
  
  const WebScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onNavigationItemSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isExtended = MediaQuery.of(context).size.width > 1200;
    
    return Scaffold(
      body: Row(
        children: [
          // Боковая навигационная панель
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavigationItemSelected,
            labelType: isExtended ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
            extended: isExtended,
            destinations: navigationItems.map((item) => 
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon ?? item.icon),
                label: Text(item.label),
              )
            ).toList(),
          ),
          
          // Вертикальный разделитель
          const VerticalDivider(thickness: 1, width: 1),
          
          // Основное содержимое
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
              ),
              body: body,
            ),
          ),
        ],
      ),
    );
  }
} 