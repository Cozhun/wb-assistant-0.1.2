import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdaptiveListItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;
  
  const AdaptiveListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.onTap,
  });
  
  @override
  _AdaptiveListItemState createState() => _AdaptiveListItemState();
}

class _AdaptiveListItemState extends State<AdaptiveListItem> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 900;
    
    return MouseRegion(
      onEnter: isDesktop ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktop ? (_) => setState(() => _isHovered = false) : null,
      child: Material(
        color: _isHovered && isDesktop
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        child: InkWell(
          onTap: widget.onTap,
          child: ListTile(
            title: Text(widget.title),
            subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
            leading: widget.leading,
            trailing: widget.trailing,
          ),
        ),
      ),
    );
  }
} 