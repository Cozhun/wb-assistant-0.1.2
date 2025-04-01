import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  
  const AdaptiveTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.initialValue,
    this.inputFormatters,
    this.maxLength,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    
    // На iOS используем CupertinoTextField
    if (platform == TargetPlatform.iOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: hintText,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        prefix: prefix ?? prefixIcon,
        suffix: suffix ?? suffixIcon,
        maxLines: maxLines,
        minLines: minLines,
        autofocus: autofocus,
        focusNode: focusNode,
        padding: contentPadding ?? const EdgeInsets.all(12),
        textCapitalization: textCapitalization,
        enabled: enabled,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
      );
    }
    
    // На других платформах используем TextField с Material Design
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon ?? prefix,
        suffixIcon: suffixIcon ?? suffix,
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        counterText: maxLength != null ? null : '',
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      enabled: enabled,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
    );
  }
}

/// Версия адаптивного текстового поля с поддержкой валидации через FormField
class AdaptiveTextFormField extends FormField<String> {
  AdaptiveTextFormField({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    String? hintText,
    String? labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    FormFieldValidator<String>? validator,
    Widget? prefix,
    Widget? suffix,
    int? maxLines = 1,
    int? minLines,
    bool autofocus = false,
    FocusNode? focusNode,
    EdgeInsetsGeometry? contentPadding,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
  }) : assert(initialValue == null || controller == null),
       super(
         key: key,
         initialValue: controller?.text ?? initialValue ?? '',
         validator: validator,
         enabled: enabled,
         builder: (FormFieldState<String> field) {
           final _AdaptiveTextFormFieldState state = field as _AdaptiveTextFormFieldState;
           
           void onChangedHandler(String value) {
             field.didChange(value);
             if (onChanged != null) {
               onChanged(value);
             }
           }
           
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               AdaptiveTextField(
                 controller: state._controller,
                 hintText: hintText,
                 labelText: labelText,
                 obscureText: obscureText,
                 keyboardType: keyboardType,
                 onChanged: onChangedHandler,
                 onEditingComplete: onEditingComplete,
                 prefix: prefix,
                 suffix: suffix,
                 maxLines: maxLines,
                 minLines: minLines,
                 autofocus: autofocus,
                 focusNode: focusNode,
                 contentPadding: contentPadding,
                 textCapitalization: textCapitalization,
                 enabled: enabled,
               ),
               if (field.hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 8, top: 4),
                   child: Text(
                     field.errorText!,
                     style: TextStyle(
                       color: Theme.of(field.context).colorScheme.error,
                       fontSize: 12,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
  
  @override
  FormFieldState<String> createState() => _AdaptiveTextFormFieldState();
}

class _AdaptiveTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  AdaptiveTextFormField get widget => super.widget as AdaptiveTextFormField;
} 