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
    super.key,
    required this.builder,
    this.smallBreakpoint = 600,
    this.largeBreakpoint = 900,
  });
  
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