import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    
    // На iOS используем CupertinoSwitch
    if (platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
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