import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double scaleFactor;
  
  const ResponsiveText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.scaleFactor = 1.0,
  });
  
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