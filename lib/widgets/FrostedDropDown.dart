import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedDropdown<T> extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<T> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final bool compact;

  const FrostedDropdown({
    Key? key,
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.compact = false,
  }) : super(key: key);

  @override
  State<FrostedDropdown<T>> createState() => _FrostedDropdownState<T>();
}

class _FrostedDropdownState<T> extends State<FrostedDropdown<T>> {
  bool _isOpen = false;
  late LayerLink _layerLink;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _layerLink = LayerLink();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry = _createOverlay();
      Overlay.of(context)!.insert(_overlayEntry!);
    }
    setState(() => _isOpen = !_isOpen);
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: widget.options.map((option) {
                      return InkWell(
                        onTap: () {
                          widget.onChanged(option);
                          _toggleDropdown();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          child: Text(
                            option.toString(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: widget.compact ? 13 : 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: widget.compact ? 15 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.selectedValue?.toString() ?? widget.label,
                      style: TextStyle(
                        color: widget.selectedValue != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white70 : Colors.black54),
                        fontSize: widget.compact ? 13 : 15,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
