# Руководство по использованию темы в приложении

## Обзор

Система тем в приложении позволяет реализовать поддержку светлой и темной темы, а также переключение между ними. Тема автоматически адаптируется под iOS и Android платформы.

## Основные компоненты

1. **AppTheme** - основной класс, который генерирует `ThemeData` в зависимости от текущих настроек
2. **ThemeProvider** - провайдер состояния темы, который позволяет переключаться между светлой и темной темой
3. **AppColors** - набор константных цветов и функций для получения цветов в зависимости от темы

## Как использовать ThemeProvider

```dart
// Получение провайдера темы
final themeProvider = Provider.of<ThemeProvider>(context);

// Проверка текущего режима
final isDarkMode = themeProvider.isDarkMode;

// Переключение темы
themeProvider.toggleTheme();

// Установка конкретного режима
themeProvider.setDarkMode(true); // включить темную тему
themeProvider.setDarkMode(false); // включить светлую тему
```

## Получение цветов, зависящих от темы

```dart
// Получение провайдера темы
final themeProvider = Provider.of<ThemeProvider>(context);
final isDarkMode = themeProvider.isDarkMode;

// Использование AppColors
final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
final textColor = AppColors.getTextColor(isDarkMode);
final cardColor = AppColors.getCardColor(isDarkMode);
```

## Адаптивные виджеты загрузки

### AdaptiveLoadingPage

`AdaptiveLoadingPage` - виджет, который отображает индикатор загрузки поверх содержимого страницы.

```dart
AdaptiveLoadingPage(
  isLoading: _isLoading, // флаг отображения загрузки
  message: 'Загрузка данных...', // опционально
  child: YourWidget(), // ваш основной виджет
)
```

### AdaptiveLoadingOverlay

`AdaptiveLoadingOverlay` - виджет, который отображает индикатор загрузки поверх содержимого с настраиваемым фоном.

```dart
AdaptiveLoadingOverlay(
  isLoading: _isLoading, // флаг отображения загрузки
  message: 'Пожалуйста, подождите...', // опционально
  child: YourWidget(), // ваш основной виджет
)
```

### AdaptiveLoadingIndicator

`AdaptiveLoadingIndicator` - простой индикатор загрузки с поддержкой различных размеров.

```dart
AdaptiveLoadingIndicator(
  size: AdaptiveLoadingSize.medium, // small, medium, large
  label: 'Загрузка...', // опционально
  color: Colors.blue, // опционально
)
```

## Рекомендации

1. **Всегда используйте цвета из темы**: Вместо использования жестко заданных цветов, используйте `Theme.of(context).colorScheme` или `AppColors`.

   ```dart
   // Правильно
   color: Theme.of(context).colorScheme.primary

   // Или с учетом темы
   color: AppColors.getTextColor(isDarkMode)

   // Не рекомендуется
   color: Colors.blue
   ```

2. **Используйте стили текста из темы**: Вместо создания собственных стилей, используйте предопределенные стили из темы.

   ```dart
   // Правильно
   style: Theme.of(context).textTheme.bodyMedium

   // Не рекомендуется
   style: TextStyle(fontSize: 16, color: Colors.black)
   ```

3. **Проверяйте виджеты в обеих темах**: Всегда тестируйте свои экраны и виджеты как в светлой, так и в темной теме.

## Демонстрационный экран

Для проверки работы тем используйте `ThemeDemoScreen`, который доступен по маршруту `/theme-demo`. 
Он показывает, как выглядят различные компоненты в разных темах.

```dart
// Переход к демо-экрану
context.go('/theme-demo');
``` 