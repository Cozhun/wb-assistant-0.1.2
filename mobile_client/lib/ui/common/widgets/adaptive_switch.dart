import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  
  const AdaptiveSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    
    // На iOS используем CupertinoSwitch
    if (platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
    
    // На других платформах используем Switch
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
} 