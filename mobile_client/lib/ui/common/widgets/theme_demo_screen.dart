import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_client/ui/common/theme/theme_provider.dart';
import 'package:mobile_client/ui/common/widgets/adaptive_loading_indicator.dart';
import 'package:mobile_client/ui/common/widgets/adaptive_loading_overlay.dart';
import 'package:mobile_client/ui/common/widgets/adaptive_loading_page.dart';

/// Демо-экран для проверки темной темы и индикаторов загрузки
class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({Key? key}) : super(key: key);

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  bool _isLoading = false;
  bool _showOverlay = false;
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return AdaptiveLoadingPage(
      isLoading: _showOverlay,
      message: 'Загрузка данных...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Демонстрация темы'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Светлая тема' : 'Темная тема',
            ),
          ],
        ),
        body: AdaptiveLoadingOverlay(
          isLoading: _isLoading,
          message: 'Пожалуйста, подождите...',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Настройки темы',
                  [
                    SwitchListTile(
                      title: const Text('Темная тема'),
                      value: isDark,
                      onChanged: (value) => themeProvider.setDarkMode(value),
                    ),
                  ],
                ),
                
                _buildSection(
                  'Индикаторы загрузки',
                  [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildIndicatorItem(
                          'Маленький',
                          AdaptiveLoadingIndicator(
                            size: AdaptiveLoadingSize.small,
                          ),
                        ),
                        _buildIndicatorItem(
                          'Средний',
                          AdaptiveLoadingIndicator(
                            size: AdaptiveLoadingSize.medium,
                          ),
                        ),
                        _buildIndicatorItem(
                          'Большой',
                          AdaptiveLoadingIndicator(
                            size: AdaptiveLoadingSize.large,
                          ),
                        ),
                        _buildIndicatorItem(
                          'С текстом',
                          AdaptiveLoadingIndicator(
                            label: 'Загрузка...',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = !_isLoading;
                            });
                          },
                          child: Text(_isLoading ? 'Скрыть индикатор' : 'Показать индикатор'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showOverlay = !_showOverlay;
                            });
                          },
                          child: Text(_showOverlay ? 'Скрыть оверлей' : 'Показать оверлей'),
                        ),
                      ],
                    ),
                  ],
                ),
                
                _buildSection(
                  'Цвета и компоненты',
                  [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Карточка',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Этот текст показывает, как выглядит карточка в ${isDark ? 'темной' : 'светлой'} теме.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Кнопка 1'),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Кнопка 2'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Кнопка 3'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildIndicatorItem(String label, Widget indicator) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 