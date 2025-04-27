import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../mobile/navigation/mobile_scaffold.dart';
import '../../web/navigation/web_scaffold.dart';
import '../../responsive/adaptive_builder.dart';
import '../../common/navigation/navigation_item.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int) onNavigationItemSelected;
  
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onNavigationItemSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, screenSize) {
        // Для веб и больших экранов используем веб-макет
        if (kIsWeb || screenSize == ScreenSize.large) {
          return WebScaffold(
            title: title,
            body: body,
            navigationItems: navigationItems,
            selectedIndex: selectedIndex,
            onNavigationItemSelected: onNavigationItemSelected,
          );
        }
        
        // Для средних и маленьких экранов используем мобильный макет
        return MobileScaffold(
          title: title,
          body: body,
          navigationItems: navigationItems,
          selectedIndex: selectedIndex,
          onNavigationItemSelected: onNavigationItemSelected,
        );
      },
    );
  }
} 