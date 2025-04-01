# Адаптация пользовательского интерфейса

## Стратегия адаптивного UI

Реализация адаптивного пользовательского интерфейса - ключевой аспект создания кросс-платформенного приложения с использованием Flutter. Цель - предоставить оптимальный опыт пользователям на разных устройствах, от мобильных телефонов до настольных браузеров.

## Структура UI-компонентов

```
mobile_client/
  ├── lib/
  │   ├── ui/
  │   │   ├── common/        # Общие компоненты
  │   │   │   ├── widgets/   # Повторно используемые виджеты
  │   │   │   ├── theme/     # Стили и темы
  │   │   │   └── layout/    # Общие макеты
  │   │   ├── mobile/        # Мобильные специфичные компоненты
  │   │   │   ├── widgets/   # Мобильные виджеты
  │   │   │   └── screens/   # Мобильные экраны
  │   │   ├── web/           # Веб-специфичные компоненты
  │   │   │   ├── widgets/   # Веб-виджеты
  │   │   │   └── pages/     # Веб-страницы
  │   │   └── screens/       # Общие экраны
  │   └── ...
```

## Responsive Framework

Для создания адаптивного UI рекомендуется использовать пакет `responsive_framework`, который предоставляет удобные инструменты для создания гибких макетов.

### Базовая настройка

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveWrapper.builder(
        child!,
        maxWidth: 1200,
        minWidth: 350,
        defaultScale: true,
        breakpoints: [
          const ResponsiveBreakpoint.resize(350, name: MOBILE),
          const ResponsiveBreakpoint.resize(600, name: TABLET),
          const ResponsiveBreakpoint.resize(900, name: DESKTOP),
          const ResponsiveBreakpoint.autoScale(1700, name: 'XL'),
        ],
      ),
      home: const AppScaffold(),
    );
  }
}
```

## Адаптивные макеты

### Основной макет приложения

```dart
// ui/common/layout/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget> actions;

  const AppScaffold({
    Key? key,
    required this.body,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Проверка ширины экрана для определения макета
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    
    // Веб-версия с боковой панелью для больших экранов
    if (kIsWeb && isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            // Боковая панель
            SideNavigationPanel(
              selectedIndex: 0, // зависит от текущего раздела
              onDestinationSelected: (index) {
                // Навигация
              },
            ),
            
            // Основной контент
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  actions: actions,
                ),
                body: body,
              ),
            ),
          ],
        ),
      );
    }
    
    // Мобильная версия с нижней навигацией
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: !isLargeScreen ? NavigationDrawer() : null,
      body: body,
      bottomNavigationBar: !isLargeScreen ? BottomNavigationPanel() : null,
    );
  }
}
```

### Боковая навигация для веб

```dart
// ui/web/widgets/side_navigation_panel.dart
import 'package:flutter/material.dart';

class SideNavigationPanel extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const SideNavigationPanel({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Главная'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Склады'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: Text('Товары'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.request_page_outlined),
          selectedIcon: Icon(Icons.request_page),
          label: Text('Заявки'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Настройки'),
        ),
      ],
    );
  }
}
```

### Адаптивная сетка элементов

```dart
// ui/common/widgets/adaptive_grid.dart
import 'package:flutter/material.dart';

class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  
  const AdaptiveGrid({
    Key? key,
    required this.children,
    this.maxCrossAxisExtent = 300.0,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
```

## Адаптивные компоненты форм

### Адаптивная форма

```dart
// ui/common/widgets/adaptive_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdaptiveForm extends StatelessWidget {
  final List<Widget> children;
  final void Function() onSubmit;
  final String submitLabel;
  
  const AdaptiveForm({
    Key? key,
    required this.children,
    required this.onSubmit,
    this.submitLabel = 'Сохранить',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 600 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children,
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onSubmit,
                  child: Text(submitLabel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Особенности платформенной адаптации UI

### Платформенные виджеты

```dart
// ui/common/widgets/platform_aware_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart' show CupertinoSwitch;

class PlatformSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const PlatformSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // На iOS используем CupertinoSwitch
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    
    // На других платформах используем Switch
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}
```

### Адаптивный диалог

```dart
// ui/common/widgets/adaptive_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  
  const AdaptiveDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.actions,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLargeScreen ? 500 : 350,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: content,
              ),
            ),
            const Divider(),
            ButtonBar(
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
```

## Специфические особенности веб-платформы

### Управление фокусом

```dart
// ui/web/widgets/focus_scope_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FocusScopeWrapper extends StatelessWidget {
  final Widget child;
  
  const FocusScopeWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    
    return FocusScope(
      autofocus: true,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          // Обработка сочетаний клавиш
        },
        child: child,
      ),
    );
  }
}
```

### Веб-специфичные компоненты ввода

```dart
// ui/web/widgets/web_text_field.dart
import 'package:flutter/material.dart';

class WebTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  
  const WebTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
        ),
        autofocus: autofocus,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }
} 