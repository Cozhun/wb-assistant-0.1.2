import 'package:flutter/material.dart';
import '../../common/navigation/navigation_item.dart';

class MobileScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int) onNavigationItemSelected;
  
  const MobileScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onNavigationItemSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: body,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'WB Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ...navigationItems.map((item) => 
              ListTile(
                selected: navigationItems.indexOf(item) == selectedIndex,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                leading: Icon(
                  navigationItems.indexOf(item) == selectedIndex
                      ? item.activeIcon ?? item.icon
                      : item.icon,
                ),
                title: Text(item.label),
                onTap: () {
                  onNavigationItemSelected(navigationItems.indexOf(item));
                  Navigator.pop(context); // закрыть drawer
                },
              )
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onNavigationItemSelected,
        items: navigationItems.map((item) => 
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon ?? item.icon),
            label: item.label,
          )
        ).toList(),
      ),
    );
  }
} 