import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';

/// Показывает адаптивный нижний лист, который выглядит и ведет себя в соответствии с платформой
Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Color? barrierColor,
}) {
  final platform = Theme.of(context).platform;
  final isIOS = platform == TargetPlatform.iOS;
  final isLargeScreen = MediaQuery.of(context).size.width > 900;
  
  // На больших экранах и веб-приложениях используем диалог вместо нижнего листа
  if (isLargeScreen || kIsWeb) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: barrierColor,
      builder: (context) {
        return Dialog(
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape ?? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: builder(context),
            ),
          ),
        );
      },
    );
  }
  
  // На iOS используем CupertinoModalPopup
  if (isIOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: isDismissible,
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: SafeArea(
            top: false,
            child: builder(context),
          ),
        );
      },
    );
  }
  
  // На других платформах используем стандартный ModalBottomSheet
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape ?? const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16.0),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    barrierColor: barrierColor,
    builder: builder,
  );
}

class AdaptiveBottomSheetItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  
  const AdaptiveBottomSheetItem({
    required this.label,
    this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}

/// Показывает адаптивный список опций в нижнем листе
Future<T?> showAdaptiveActionSheet<T>({
  required BuildContext context,
  required List<AdaptiveBottomSheetItem> items,
  String? title,
  String? message,
  AdaptiveBottomSheetItem? cancelItem,
}) {
  final platform = Theme.of(context).platform;
  final isIOS = platform == TargetPlatform.iOS;
  
  // Для iOS используем встроенный CupertinoActionSheet
  if (isIOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: items.map((item) {
            return CupertinoActionSheetAction(
              onPressed: () {
                if (item.onTap != null) {
                  Navigator.of(context).pop();
                  item.onTap!();
                } else {
                  Navigator.of(context).pop(item);
                }
              },
              isDestructiveAction: item.isDestructive,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      color: item.isDestructive ? CupertinoColors.destructiveRed : null,
                      size: 22.0,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  Text(item.label),
                ],
              ),
            );
          }).toList(),
          cancelButton: cancelItem != null ? CupertinoActionSheetAction(
            onPressed: () {
              if (cancelItem.onTap != null) {
                Navigator.of(context).pop();
                cancelItem.onTap!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(cancelItem.label),
          ) : null,
        );
      },
    );
  }
  
  // Для других платформ создаем Material-версию
  return showAdaptiveBottomSheet<T>(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || message != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                  if (message != null) ...[
                    if (title != null) const SizedBox(height: 8.0),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
          ],
          ...items.map((item) {
            final textColor = item.isDestructive ? Colors.red : null;
            
            return ListTile(
              leading: item.icon != null ? Icon(item.icon, color: textColor) : null,
              title: Text(
                item.label,
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                if (item.onTap != null) {
                  Navigator.of(context).pop();
                  item.onTap!();
                } else {
                  Navigator.of(context).pop(item);
                }
              },
            );
          }),
          if (cancelItem != null) ...[
            const Divider(),
            ListTile(
              leading: cancelItem.icon != null ? Icon(cancelItem.icon) : null,
              title: Text(cancelItem.label),
              onTap: () {
                if (cancelItem.onTap != null) {
                  Navigator.of(context).pop();
                  cancelItem.onTap!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          const SizedBox(height: 8.0),
        ],
      );
    },
  );
} 