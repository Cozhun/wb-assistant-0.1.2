import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

class AdaptiveDropdownItem<T> {
  final String label;
  final T value;
  final Widget? icon;
  
  const AdaptiveDropdownItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

class AdaptiveDropdown<T> extends StatelessWidget {
  final List<AdaptiveDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? label;
  final bool isExpanded;
  final Widget? icon;
  final Color? dropdownColor;
  final bool isDense;
  
  const AdaptiveDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.label,
    this.isExpanded = false,
    this.icon,
    this.dropdownColor,
    this.isDense = false,
  });
  
  Future<void> _showCupertinoModal(BuildContext context) async {
    final result = await showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250.0,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              // Кнопка "Готово"
              Container(
                height: 44.0,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Готово',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Разделитель
              Container(
                height: 1.0,
                color: CupertinoColors.systemGrey5,
              ),
              // Список опций
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: CupertinoColors.systemBackground,
                  itemExtent: 40.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: value != null
                        ? items.indexWhere((item) => item.value == value)
                        : 0,
                  ),
                  onSelectedItemChanged: (int index) {
                    onChanged(items[index].value);
                  },
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.icon != null) ...[
                            item.icon!,
                            const SizedBox(width: 8.0),
                          ],
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    if (result != null) {
      onChanged(result);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    
    // На iOS используем CupertinoButton, который открывает CupertinoPicker
    if (platform == TargetPlatform.iOS) {
      // Найдем выбранный элемент
      final selectedItem = value != null
          ? items.firstWhere((item) => item.value == value,
              orElse: () => items.first)
          : null;
      
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          onPressed: () => _showCupertinoModal(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedItem != null) ...[
                Row(
                  children: [
                    if (selectedItem.icon != null) ...[
                      selectedItem.icon!,
                      const SizedBox(width: 8.0),
                    ],
                    Text(
                      selectedItem.label,
                      style: const TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ] else if (hint != null) ...[
                Text(
                  hint!,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16.0,
                  ),
                ),
              ],
              const Icon(
                CupertinoIcons.chevron_down,
                size: 16.0,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      );
    }
    
    // На других платформах используем DropdownButtonFormField с Material Design
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isDense ? 10.0 : 16.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    item.icon!,
                    const SizedBox(width: 8.0),
                  ],
                  Text(item.label),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          hint: hint != null ? Text(hint!) : null,
          icon: icon ?? const Icon(Icons.arrow_drop_down),
          isExpanded: isExpanded,
          dropdownColor: dropdownColor,
          isDense: isDense,
        ),
      ),
    );
  }
} 