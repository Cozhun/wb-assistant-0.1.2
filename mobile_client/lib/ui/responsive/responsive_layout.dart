import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget? tabletView;
  final Widget desktopView;
  final double mobileBreakpoint;
  final double desktopBreakpoint;
  
  const ResponsiveLayout({
    super.key,
    required this.mobileView,
    this.tabletView,
    required this.desktopView,
    this.mobileBreakpoint = 600,
    this.desktopBreakpoint = 900,
  });
  
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