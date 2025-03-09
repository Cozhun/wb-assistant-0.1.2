import 'package:flutter/material.dart';

/// Виджет для отображения индикатора загрузки
class LoadingIndicator extends StatelessWidget {
  final double size;
  final String? message;
  final bool isOverlay;

  const LoadingIndicator({
    super.key,
    this.size = 24.0,
    this.message,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size / 8,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );

    if (isOverlay) {
      return Stack(
        children: [
          const ModalBarrier(
            color: Colors.black38,
            dismissible: false,
          ),
          loadingWidget,
        ],
      );
    }

    return loadingWidget;
  }
}

/// Виджет для отображения индикатора загрузки над контентом
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          LoadingIndicator(
            isOverlay: true,
            message: message,
          ),
      ],
    );
  }
} 