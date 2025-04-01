# Кросс-платформенная адаптация UI

## Обзор

В данном документе описаны подходы и стратегии для создания кросс-платформенного пользовательского интерфейса в Flutter, учитывающего особенности как веб, так и мобильных платформ (Android и iOS). Особое внимание уделяется адаптации макетов для различных размеров экрана, платформенно-зависимым компонентам и обеспечению единого пользовательского опыта.

## Принципы адаптивного дизайна

### Респонсивная структура (CL: 95%)

Для обеспечения адаптивности приложения на различных устройствах рекомендуется использовать комбинацию встроенных возможностей Flutter и специализированные пакеты.

#### Использование ResponsiveBuilder (CL: 90%)

Пакет `responsive_builder` позволяет создавать адаптивные макеты на основе размера экрана:

```dart
import 'package:responsive_builder/responsive_builder.dart';

class AdaptiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Проверка типа устройства
        if (sizingInformation.deviceScreenType == DeviceScreenType.desktop) {
          return DesktopLayout();
        }
        
        if (sizingInformation.deviceScreenType == DeviceScreenType.tablet) {
          return TabletLayout();
        }
        
        return MobileLayout();
      },
    );
  }
}
```

**Обоснование**: `ResponsiveBuilder` предоставляет простой и читаемый способ создания адаптивных макетов с выбором соответствующего компонента в зависимости от типа устройства.

**Источники**:
- [responsive_builder на pub.dev](https://pub.dev/packages/responsive_builder)
- [Building Responsive UIs in Flutter](https://medium.com/flutter-community/building-responsive-uis-in-flutter-e0cdbba21ebc)

#### Использование MediaQuery (CL: 95%)

Встроенный механизм Flutter для получения информации о размере экрана:

```dart
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 900;
    final isMediumScreen = size.width > 600 && size.width <= 900;
    final isSmallScreen = size.width <= 600;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
      child: isLargeScreen
          ? LargeScreenContent()
          : isMediumScreen
              ? MediumScreenContent()
              : SmallScreenContent(),
    );
  }
}
```

**Обоснование**: `MediaQuery` является встроенным механизмом Flutter для определения размеров экрана, ориентации и других свойств, что делает его универсальным решением для простых случаев адаптации.

**Источники**:
- [MediaQuery в Flutter](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- [Responsive Applications with MediaQuery](https://flutter.dev/docs/development/ui/layout/responsive)

### Структура адаптивных макетов (CL: 90%)

Для организации кода рекомендуется использовать следующую структуру:

```
lib/
  ├── ui/
  │   ├── common/          # Общие компоненты для всех платформ
  │   │   ├── widgets/     # Общие виджеты
  │   │   ├── theme/       # Темы
  │   │   └── layout/      # Общие макеты
  │   ├── responsive/      # Адаптивные компоненты
  │   │   ├── adaptive_builder.dart     # Обертка для построения адаптивных UI
  │   │   ├── responsive_layout.dart    # Макет с переключением для разных размеров
  │   │   └── breakpoints.dart          # Определение точек перехода для разных размеров
  │   ├── screens/         # Экраны приложения
  │   │   ├── warehouse/   # Модуль управления складом
  │   │   │   ├── warehouse_screen.dart       # Основной экран
  │   │   │   ├── desktop_warehouse_view.dart # Реализация для десктопа
  │   │   │   └── mobile_warehouse_view.dart  # Реализация для мобильных
  │   │   └── ...
  │   ├── mobile/          # Специфические компоненты для мобильных
  │   │   ├── widgets/     # Мобильные виджеты
  │   │   └── navigation/  # Мобильная навигация
  │   └── web/             # Специфические компоненты для веб
  │       ├── widgets/     # Веб-виджеты
  │       └── navigation/  # Веб-навигация
```

**Обоснование**: Четкая структура каталогов улучшает организацию кода, упрощает навигацию и обеспечивает ясность в реализации кросс-платформенной логики.

### Создание базовых компонентов (CL: 90%)

#### Адаптивная обертка для экранов:

```dart
// ui/responsive/adaptive_builder.dart
import 'package:flutter/material.dart';

enum ScreenSize {
  small,  // мобильные телефоны
  medium, // планшеты и маленькие десктопы
  large,  // большие десктопы
}

class AdaptiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;
  final double smallBreakpoint;
  final double largeBreakpoint;
  
  const AdaptiveBuilder({
    Key? key,
    required this.builder,
    this.smallBreakpoint = 600,
    this.largeBreakpoint = 900,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    ScreenSize screenSize;
    if (width <= smallBreakpoint) {
      screenSize = ScreenSize.small;
    } else if (width <= largeBreakpoint) {
      screenSize = ScreenSize.medium;
    } else {
      screenSize = ScreenSize.large;
    }
    
    return builder(context, screenSize);
  }
}
```

**Обоснование**: Создание собственной адаптивной обертки упрощает логику определения размера экрана в компонентах, что делает код более читаемым и поддерживаемым.

#### Респонсивный макет для переключения между разными представлениями:

```dart
// ui/responsive/responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget? tabletView;
  final Widget desktopView;
  final double mobileBreakpoint;
  final double desktopBreakpoint;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobileView,
    this.tabletView,
    required this.desktopView,
    this.mobileBreakpoint = 600,
    this.desktopBreakpoint = 900,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    if (width >= desktopBreakpoint) {
      return desktopView;
    }
    
    if (width >= mobileBreakpoint) {
      return tabletView ?? desktopView;
    }
    
    return mobileView;
  }
}
```

**Обоснование**: Данный компонент обеспечивает четкую структуру для переключения между различными представлениями в зависимости от размера экрана, с возможностью настройки точек переключения.

## Адаптация навигации

### Стратегия навигации (CL: 85%)

Различные платформы имеют различные ожидания пользователей относительно навигации. Рекомендуется использовать следующие подходы:

#### Веб-навигация с боковой панелью (CL: 90%)

```dart
// ui/web/navigation/web_scaffold.dart
import 'package:flutter/material.dart';

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
    return Scaffold(
      body: Row(
        children: [
          // Боковая навигационная панель
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavigationItemSelected,
            labelType: NavigationRailLabelType.all,
            destinations: navigationItems.map((item) => 
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon ?? item.icon),
                label: Text(item.label),
              )
            ).toList(),
            extended: MediaQuery.of(context).size.width > 1200,
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

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  
  const NavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}
```

**Обоснование**: Боковая навигационная панель является стандартным паттерном для веб-приложений и обеспечивает быстрый доступ к основным разделам. `NavigationRail` - встроенный компонент Flutter, который идеально подходит для этого случая.

**Источники**:
- [NavigationRail в Flutter](https://api.flutter.dev/flutter/material/NavigationRail-class.html)
- [Material Design Navigation Patterns](https://material.io/design/navigation/understanding-navigation.html)

#### Мобильная навигация с нижней панелью (CL: 90%)

```dart
// ui/mobile/navigation/mobile_scaffold.dart
import 'package:flutter/material.dart';

class MobileScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int) onNavigationItemSelected;
  
  const MobileScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onNavigationItemSelected,
  }) : super(key: key);
  
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
            ).toList(),
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
```

**Обоснование**: Нижняя навигационная панель в сочетании с боковым drawer является стандартным паттерном для мобильных приложений. Это обеспечивает быстрый доступ к основным разделам и полный список всех разделов в drawer.

**Источники**:
- [BottomNavigationBar в Flutter](https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html)
- [Drawer в Flutter](https://api.flutter.dev/flutter/material/Drawer-class.html)

### Адаптивная навигация (CL: 85%)

Для объединения навигации на разных платформах рекомендуется создать адаптивную обертку:

```dart
// ui/common/layout/adaptive_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../responsive/adaptive_builder.dart';
import '../../web/navigation/web_scaffold.dart';
import '../../mobile/navigation/mobile_scaffold.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int) onNavigationItemSelected;
  
  const AdaptiveScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onNavigationItemSelected,
  }) : super(key: key);
  
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
```

**Обоснование**: Этот подход обеспечивает единый интерфейс для навигации, но с учетом особенностей платформы и размера экрана, при этом сохраняя возможность переиспользования кода.

## Платформо-зависимые компоненты

### Адаптивные диалоги (CL: 85%)

Диалоговые окна также должны учитывать особенности платформы:

```dart
// ui/common/widgets/adaptive_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart' show CupertinoAlertDialog;

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<DialogAction> actions;
  
  const AdaptiveDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.actions,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = theme.platform == TargetPlatform.iOS;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    
    // На веб и больших экранах всегда используем Material диалог
    if (kIsWeb || isLargeScreen) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: isLargeScreen ? 500 : 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(content, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: action.onPressed,
                            style: action.isDestructive
                                ? ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  )
                                : null,
                            child: Text(action.label),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }
    
    // На iOS используем CupertinoAlertDialog
    if (isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions
            .map((action) => CupertinoDialogAction(
                  onPressed: action.onPressed,
                  isDestructiveAction: action.isDestructive,
                  child: Text(action.label),
                ))
            .toList(),
      );
    }
    
    // На Android используем AlertDialog
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: actions
          .map((action) => TextButton(
                onPressed: action.onPressed,
                style: action.isDestructive
                    ? TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      )
                    : null,
                child: Text(action.label),
              ))
          .toList(),
    );
  }
}

class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}
```

**Обоснование**: Адаптивный диалог учитывает как платформу (Material/Cupertino), так и размер экрана, предоставляя оптимальный пользовательский опыт на каждой платформе.

**Источники**:
- [AlertDialog в Flutter](https://api.flutter.dev/flutter/material/AlertDialog-class.html)
- [CupertinoAlertDialog в Flutter](https://api.flutter.dev/flutter/cupertino/CupertinoAlertDialog-class.html)

### Адаптивные платформенные компоненты (CL: 90%)

Для создания компонентов, соответствующих ожиданиям пользователей на каждой платформе, рекомендуется создавать адаптивные версии:

```dart
// ui/common/widgets/adaptive_switch.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  
  const AdaptiveSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    
    // На iOS используем CupertinoSwitch
    if (platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
    
    // На других платформах используем Switch
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
}
```

**Обоснование**: Использование адаптивных компонентов обеспечивает естественное поведение и внешний вид, соответствующий ожиданиям пользователей на каждой платформе.

**Источники**:
- [Switch в Flutter](https://api.flutter.dev/flutter/material/Switch-class.html)
- [CupertinoSwitch в Flutter](https://api.flutter.dev/flutter/cupertino/CupertinoSwitch-class.html)

## Адаптация для различных входных методов

### Адаптивные элементы взаимодействия (CL: 80%)

Различные платформы предполагают различные способы взаимодействия: на мобильных устройствах используются касания, на десктопе — мышь и клавиатура.

```dart
// ui/common/widgets/adaptive_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdaptiveListItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;
  
  const AdaptiveListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.onTap,
  }) : super(key: key);
  
  @override
  _AdaptiveListItemState createState() => _AdaptiveListItemState();
}

class _AdaptiveListItemState extends State<AdaptiveListItem> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 900;
    
    return MouseRegion(
      onEnter: isDesktop ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktop ? (_) => setState(() => _isHovered = false) : null,
      child: Material(
        color: _isHovered && isDesktop
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: InkWell(
          onTap: widget.onTap,
          child: ListTile(
            title: Text(widget.title),
            subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
            leading: widget.leading,
            trailing: widget.trailing,
          ),
        ),
      ),
    );
  }
}
```

**Обоснование**: Адаптивные элементы взаимодействия обеспечивают соответствующий отклик на различные входные методы, улучшая пользовательский опыт на всех платформах.

### Отзывчивые к наведению элементы (CL: 75%)

Для десктопных приложений важно обеспечить отзывчивость при наведении курсора:

```dart
// ui/web/widgets/hover_button.dart
import 'package:flutter/material.dart';

class HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  
  const HoverButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  }) : super(key: key);
  
  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.primaryColor;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: _isHovered ? Colors.white : color,
          backgroundColor: _isHovered ? color : Colors.transparent,
          elevation: _isHovered ? 4 : 0,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: theme.textTheme.titleMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon),
              const SizedBox(width: 8),
            ],
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}
```

**Обоснование**: Отзывчивость при наведении курсора является важным аспектом UX на десктопных платформах, предоставляя пользователю визуальную обратную связь.

## Адаптация для различных плотностей экрана

### Масштабируемые компоненты (CL: 85%)

Для обеспечения хорошего внешнего вида на различных DPI экранах, рекомендуется использовать масштабируемые компоненты:

```dart
// ui/common/widgets/responsive_text.dart
import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double scaleFactor;
  
  const ResponsiveText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.scaleFactor = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaleFactor * scaleFactor;
    
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
    );
  }
}
```

**Обоснование**: Масштабируемые компоненты обеспечивают правильное отображение на экранах с различной плотностью пикселей, учитывая настройки системы.

**Источники**:
- [Text в Flutter](https://api.flutter.dev/flutter/widgets/Text-class.html)
- [MediaQuery в Flutter](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)

## Организация тем и стилей

### Единая тема с платформенными адаптациями (CL: 90%)

Для обеспечения единого внешнего вида с учетом особенностей платформы рекомендуется использовать адаптивные темы:

```dart
// ui/common/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  static ThemeData getTheme(BuildContext context, {bool isDark = false}) {
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    
    // Основные цвета
    final primaryColor = Colors.blue;
    final accentColor = Colors.amber;
    
    if (isIOS) {
      // iOS-специфичная тема
      return ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: CupertinoColors.systemBackground,
          foregroundColor: primaryColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    
    // Material тема
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        secondary: accentColor,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
```

**Обоснование**: Адаптивные темы обеспечивают единый визуальный язык приложения на всех платформах, но с учетом платформенных особенностей, что улучшает пользовательский опыт.

**Источники**:
- [ThemeData в Flutter](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [CupertinoThemeData в Flutter](https://api.flutter.dev/flutter/cupertino/CupertinoThemeData-class.html)

## Тестирование UI на различных платформах

### Подходы к тестированию (CL: 80%)

Для обеспечения корректного отображения и функционирования на всех платформах рекомендуется использовать комбинацию подходов к тестированию:

1. **Юнит-тестирование компонентов** - проверка отдельных компонентов на корректное поведение
2. **Виджет-тестирование** - проверка рендеринга и взаимодействия на уровне виджетов
3. **Интеграционное тестирование** - проверка взаимодействия между компонентами
4. **Кросс-платформенное тестирование** - проверка отображения на различных устройствах и платформах

#### Пример теста для адаптивного компонента:

```dart
// test/ui/common/widgets/adaptive_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/ui/common/widgets/adaptive_switch.dart';

void main() {
  testWidgets('AdaptiveSwitch uses CupertinoSwitch on iOS',
      (WidgetTester tester) async {
    bool value = false;
    
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.iOS,
        ),
        home: Scaffold(
          body: AdaptiveSwitch(
            value: value,
            onChanged: (newValue) => value = newValue,
          ),
        ),
      ),
    );
    
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
  
  testWidgets('AdaptiveSwitch uses Switch on Android',
      (WidgetTester tester) async {
    bool value = false;
    
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
        ),
        home: Scaffold(
          body: AdaptiveSwitch(
            value: value,
            onChanged: (newValue) => value = newValue,
          ),
        ),
      ),
    );
    
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsNothing);
  });
  
  testWidgets('AdaptiveSwitch responds to tap',
      (WidgetTester tester) async {
    bool value = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AdaptiveSwitch(
                value: value,
                onChanged: (newValue) {
                  setState(() => value = newValue);
                },
              );
            },
          ),
        ),
      ),
    );
    
    await tester.tap(find.byType(Switch));
    await tester.pump();
    
    expect(value, true);
  });
}
```

**Обоснование**: Тестирование адаптивных компонентов на различных платформах обеспечивает уверенность в корректной работе приложения на всех поддерживаемых устройствах.

**Источники**:
- [Testing Flutter Apps](https://flutter.dev/docs/testing)
- [Widget Testing в Flutter](https://flutter.dev/docs/testing/testing-frameworks#widget-tests)

## Заключение

Кросс-платформенная адаптация UI является ключевым аспектом разработки приложения на Flutter, обеспечивая оптимальный пользовательский опыт на всех поддерживаемых платформах. Использование адаптивных компонентов, респонсивных макетов и платформенно-зависимых стилей позволяет создать приложение, которое выглядит и функционирует естественно на каждой платформе, при этом максимально переиспользуя код. 