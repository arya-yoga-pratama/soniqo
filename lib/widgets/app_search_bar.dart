import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  const AppSearchBar({super.key, required this.controller});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 420,
        height: 44,
        decoration: BoxDecoration(
          color: _isFocused
              ? const Color(0xFF1E1535)
              : _isHovered
                  ? const Color(0xFF181818)
                  : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _isFocused
                ? const Color(0xFF7C3AED).withValues(alpha: 0.95)
                : _isHovered
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.6)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.3),
            width: _isFocused ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(
                alpha: _isFocused ? 0.35 : 0.12,
              ),
              blurRadius: _isFocused ? 20 : 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: _isFocused ? const Color(0xFF9D6FEF) : Colors.white38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: widget.controller.text.isNotEmpty
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          widget.controller.clear();
                          _focusNode.requestFocus();
                        },
                        child: Container(
                          key: const ValueKey('clear_button'),
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: 37, key: ValueKey('empty_clear')),
            ),
          ],
        ),
      ),
    );
  }
}
