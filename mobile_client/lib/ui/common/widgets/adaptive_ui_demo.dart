import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../layout/adaptive_scaffold.dart';
import '../navigation/navigation_item.dart';
import 'adaptive_switch.dart';
import 'adaptive_list_item.dart';
import 'responsive_text.dart';
import 'adaptive_dialog.dart';
import 'adaptive_text_field.dart';
import 'adaptive_dropdown.dart';
import 'adaptive_card.dart';
import 'adaptive_loading_indicator.dart';
import 'adaptive_loading_overlay.dart';
import 'adaptive_bottom_sheet.dart';
import '../../web/widgets/hover_button.dart';

class AdaptiveUiDemo extends StatefulWidget {
  const AdaptiveUiDemo({super.key});

  @override
  _AdaptiveUiDemoState createState() => _AdaptiveUiDemoState();
}

class _AdaptiveUiDemoState extends State<AdaptiveUiDemo> {
  int _selectedIndex = 0;
  bool _switchValue = false;
  String _textFieldValue = '';
  String? _selectedDropdownValue;
  bool _isLoading = false;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      label: 'Главная',
      icon: Icons.home,
      activeIcon: Icons.home_filled,
    ),
    NavigationItem(
      label: 'Заказы',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
    ),
    NavigationItem(
      label: 'Запросы',
      icon: Icons.question_answer_outlined,
      activeIcon: Icons.question_answer,
    ),
    NavigationItem(
      label: 'Настройки',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  final List<AdaptiveDropdownItem<String>> _dropdownItems = [
    const AdaptiveDropdownItem(
      label: 'Опция 1',
      value: 'option1',
      icon: Icon(Icons.star),
    ),
    const AdaptiveDropdownItem(
      label: 'Опция 2',
      value: 'option2',
      icon: Icon(Icons.favorite),
    ),
    const AdaptiveDropdownItem(
      label: 'Опция 3',
      value: 'option3',
      icon: Icon(Icons.settings),
    ),
  ];
  
  final List<AdaptiveBottomSheetItem> _bottomSheetItems = [
    AdaptiveBottomSheetItem(
      label: 'Поделиться',
      icon: Icons.share,
      onTap: () {},
    ),
    AdaptiveBottomSheetItem(
      label: 'Редактировать',
      icon: Icons.edit,
      onTap: () {},
    ),
    AdaptiveBottomSheetItem(
      label: 'Архивировать',
      icon: Icons.archive,
      onTap: () {},
    ),
    AdaptiveBottomSheetItem(
      label: 'Удалить',
      icon: Icons.delete,
      isDestructive: true,
      onTap: () {},
    ),
  ];

  void _onNavigationItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAdaptiveDialogDemo() {
    showCustomActionsDialog(
      context: context,
      title: 'Адаптивный диалог',
      content: 'Это пример адаптивного диалога, который выглядит нативно на разных платформах.',
      actions: [
        DialogAction(
          label: 'Отмена',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        DialogAction(
          label: 'Подтвердить',
          onPressed: () {
            Navigator.of(context).pop();
          },
          isPrimary: true,
        ),
      ],
    );
  }
  
  void _showAdaptiveBottomSheetDemo() {
    showAdaptiveBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Адаптивный нижний лист',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Это пример адаптивного нижнего листа, который выглядит нативно на разных платформах. На мобильных устройствах он отображается как bottom sheet, а на веб и больших экранах - как диалог.',
              ),
              const SizedBox(height: 24.0),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Введите комментарий',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showAdaptiveActionSheetDemo() {
    showAdaptiveActionSheet(
      context: context,
      title: 'Действия с элементом',
      message: 'Выберите действие для выполнения',
      items: _bottomSheetItems,
      cancelItem: AdaptiveBottomSheetItem(
        label: 'Отмена',
        onTap: () {},
      ),
    );
  }
  
  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
    
    if (_isLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 900;

    return Stack(
      children: [
        AdaptiveScaffold(
          title: 'Адаптивный UI',
          navigationItems: _navigationItems,
          selectedIndex: _selectedIndex,
          onNavigationItemSelected: _onNavigationItemSelected,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ResponsiveText(
                  text: 'Демонстрация адаптивных компонентов',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивный переключатель
                const ResponsiveText(
                  text: 'Адаптивный переключатель:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    AdaptiveSwitch(
                      value: _switchValue,
                      onChanged: (value) {
                        setState(() {
                          _switchValue = value;
                        });
                      },
                    ),
                    const SizedBox(width: 10.0),
                    Text(_switchValue ? 'Включено' : 'Выключено'),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные текстовые поля
                const ResponsiveText(
                  text: 'Адаптивные текстовые поля:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                AdaptiveTextField(
                  labelText: 'Обычное текстовое поле',
                  hintText: 'Введите текст',
                  onChanged: (value) {
                    setState(() {
                      _textFieldValue = value;
                    });
                  },
                ),
                const SizedBox(height: 10.0),
                AdaptiveTextField(
                  labelText: 'Поле с паролем',
                  hintText: 'Введите пароль',
                  obscureText: true,
                  suffix: const Icon(Icons.visibility),
                ),
                const SizedBox(height: 10.0),
                AdaptiveTextFormField(
                  labelText: 'Поле с валидацией',
                  hintText: 'Обязательное поле',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Поле не может быть пустым';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивное выпадающее меню
                const ResponsiveText(
                  text: 'Адаптивное выпадающее меню:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                AdaptiveDropdown<String>(
                  label: 'Выберите опцию',
                  hint: 'Не выбрано',
                  items: _dropdownItems,
                  value: _selectedDropdownValue,
                  onChanged: (value) {
                    setState(() {
                      _selectedDropdownValue = value;
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные нижние листы
                const ResponsiveText(
                  text: 'Адаптивные нижние листы:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    ElevatedButton(
                      onPressed: _showAdaptiveBottomSheetDemo,
                      child: const Text('Показать нижний лист'),
                    ),
                    ElevatedButton(
                      onPressed: _showAdaptiveActionSheetDemo,
                      child: const Text('Показать лист действий'),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные карточки
                const ResponsiveText(
                  text: 'Адаптивные карточки:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                AdaptiveCard(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Обычная карточка',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      const Text('Нажмите на карточку для действия. Карточка адаптируется под платформу и реагирует на события взаимодействия.'),
                    ],
                  ),
                ),
                AdaptiveCard(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  elevation: 4.0,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цветная карточка',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      const Text('Карточка с пользовательским цветом и повышенной тенью.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные элементы списка
                const ResponsiveText(
                  text: 'Адаптивные элементы списка:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Card(
                  child: Column(
                    children: [
                      AdaptiveListItem(
                        title: 'Элемент 1',
                        subtitle: 'С поддержкой отзывчивости при наведении',
                        leading: const Icon(Icons.star),
                        onTap: () {},
                      ),
                      const Divider(),
                      AdaptiveListItem(
                        title: 'Элемент 2',
                        subtitle: 'Нажмите для просмотра деталей',
                        leading: const Icon(Icons.info),
                        onTap: () {},
                      ),
                      const Divider(),
                      AdaptiveListItem(
                        title: 'Элемент 3',
                        leading: const Icon(Icons.settings),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные индикаторы загрузки
                const ResponsiveText(
                  text: 'Адаптивные индикаторы загрузки:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    AdaptiveLoadingIndicator(
                      size: AdaptiveLoadingSize.small,
                      label: 'Маленький',
                    ),
                    AdaptiveLoadingIndicator(
                      size: AdaptiveLoadingSize.medium,
                      label: 'Средний',
                    ),
                    AdaptiveLoadingIndicator(
                      size: AdaptiveLoadingSize.large,
                      label: 'Большой',
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: ElevatedButton(
                    onPressed: _toggleLoading,
                    child: const Text('Показать оверлей загрузки'),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                
                // Адаптивные кнопки
                const ResponsiveText(
                  text: 'Адаптивные кнопки:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    ElevatedButton(
                      onPressed: _showAdaptiveDialogDemo,
                      child: const Text('Показать диалог'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Отменить'),
                    ),
                    if (isDesktop) ...[
                      HoverButton(
                        label: 'Hover кнопка',
                        icon: Icons.touch_app,
                        onPressed: () {},
                      ),
                      HoverButton(
                        label: 'Hover кнопка с цветом',
                        icon: Icons.color_lens,
                        color: Colors.green,
                        onPressed: () {},
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
        
        // Показываем оверлей загрузки, если _isLoading == true
        if (_isLoading)
          const AdaptiveLoadingOverlay(
            message: 'Загрузка...',
            isLoading: true,
            child: SizedBox(),
          ),
      ],
    );
  }
} 