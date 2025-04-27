import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';

/// Класс для описания действия в диалоге
class DialogAction {
  /// Надпись на кнопке
  final String label;
  
  /// Функция, вызываемая при нажатии
  final VoidCallback onPressed;
  
  /// Является ли опасным действием (будет выделено красным)
  final bool isDestructive;
  
  /// Является ли основным действием (будет выделено)
  final bool isPrimary;
  
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
  });
}

/// Показывает адаптивный диалог, адаптированный под платформу
Future<T?> showAppAdaptiveDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  String? cancelText,
  String? confirmText,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool barrierDismissible = true,
}) async {
  final platform = Theme.of(context).platform;
  
  if (platform == TargetPlatform.iOS) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: _buildActions<T>(
          context,
          cancelText: cancelText,
          confirmText: confirmText,
          onCancel: onCancel,
          onConfirm: onConfirm,
        ),
      ),
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: _buildActions<T>(
          context,
          cancelText: cancelText,
          confirmText: confirmText,
          onCancel: onCancel,
          onConfirm: onConfirm,
        ),
      ),
    );
  }
}

/// Построение кнопок действий для диалога
List<Widget> _buildActions<T>(
  BuildContext context, {
  String? cancelText,
  String? confirmText,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
}) {
  final platform = Theme.of(context).platform;
  final result = <Widget>[];
  
  // Кнопка отмены
  if (cancelText != null) {
    if (platform == TargetPlatform.iOS) {
      result.add(CupertinoDialogAction(
        isDestructiveAction: true,
        onPressed: () {
          onCancel?.call();
          Navigator.of(context).pop(false as T?);
        },
        child: Text(cancelText),
      ));
    } else {
      result.add(TextButton(
        onPressed: () {
          onCancel?.call();
          Navigator.of(context).pop(false as T?);
        },
        child: Text(cancelText),
      ));
    }
  }
  
  // Кнопка подтверждения
  if (confirmText != null) {
    if (platform == TargetPlatform.iOS) {
      result.add(CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () {
          onConfirm?.call();
          Navigator.of(context).pop(true as T?);
        },
        child: Text(confirmText),
      ));
    } else {
      result.add(TextButton(
        onPressed: () {
          onConfirm?.call();
          Navigator.of(context).pop(true as T?);
        },
        child: Text(confirmText),
      ));
    }
  }
  
  return result;
}

/// Показывает адаптивный диалог с настраиваемым содержимым
Future<void> showCustomAppDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) async {
  final platform = Theme.of(context).platform;
  
  if (platform == TargetPlatform.iOS) {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: content,
        actions: actions ?? [],
      ),
    );
  } else {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      ),
    );
  }
}

/// Функция-помощник для отображения адаптивного диалога с собственными действиями
Future<void> showCustomActionsDialog({
  required BuildContext context,
  required String title,
  required String content,
  required List<DialogAction> actions,
}) async {
  final platform = Theme.of(context).platform;
  final dialogActions = _buildCustomActionWidgets(context, actions);
  
  if (platform == TargetPlatform.iOS) {
    await showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: dialogActions,
      ),
    );
  } else {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: dialogActions,
      ),
    );
  }
}

/// Строит кнопки для диалога на основе DialogAction
List<Widget> _buildCustomActionWidgets(BuildContext context, List<DialogAction> actions) {
  final platform = Theme.of(context).platform;
  final result = <Widget>[];
  
  for (var action in actions) {
    if (platform == TargetPlatform.iOS) {
      result.add(
        CupertinoDialogAction(
          isDestructiveAction: action.isDestructive,
          isDefaultAction: action.isPrimary,
          onPressed: () async {
            // Сначала закрываем диалог
            final customAction = action.onPressed;
            await Future.microtask(() => customAction());
          },
          child: Text(action.label),
        ),
      );
    } else {
      final textColor = action.isDestructive 
          ? Colors.red 
          : (action.isPrimary ? Theme.of(context).colorScheme.primary : null);
          
      result.add(
        TextButton(
          onPressed: () async {
            // Сначала закрываем диалог
            final customAction = action.onPressed;
            await Future.microtask(() => customAction());
          },
          style: TextButton.styleFrom(
            foregroundColor: textColor,
          ),
          child: Text(action.label),
        ),
      );
    }
  }
  
  return result;
}

/// Функция для отображения диалога с действиями
/// Заменяет прямые вызовы showAdaptiveDialog
Future<T?> showAppDialogWithActions<T>({
  required BuildContext context,
  required String title,
  required dynamic content,  // Может быть String или Widget
  required List<DialogAction> actions,
  WidgetBuilder? builder,
  bool barrierDismissible = true,
}) async {
  final platform = Theme.of(context).platform;
  
  // Создаём копию действий с обработкой возможных конфликтов навигатора
  final safeActions = actions.map((action) => DialogAction(
    label: action.label,
    isDestructive: action.isDestructive,
    isPrimary: action.isPrimary,
    onPressed: () {
      // Используем rootNavigator для предотвращения конфликта с вложенными навигаторами
      Navigator.of(context, rootNavigator: true).pop();
      
      // Добавляем небольшую задержку перед выполнением действия
      // чтобы избежать конфликта с закрытием диалога
      Future.delayed(Duration(milliseconds: 50), () {
        action.onPressed();
            });
    },
  )).toList();
  
  final dialogActions = _buildCustomActionWidgets(context, safeActions);
  
  Widget contentWidget;
  if (content is String) {
    contentWidget = Text(content);
  } else if (content is Widget) {
    contentWidget = content;
  } else if (builder != null) {
    contentWidget = builder(context);
  } else {
    contentWidget = const Text('Содержимое не указано');
  }
  
  if (platform == TargetPlatform.iOS) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget,
        actions: dialogActions,
      ),
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: contentWidget,
        actions: dialogActions,
      ),
    );
  }
} 