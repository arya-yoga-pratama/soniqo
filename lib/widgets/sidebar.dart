import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final String selectedMenu;
  final ValueChanged<String> onMenuSelected;

  const Sidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accentColor = themeProvider.accentColor;
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isExpanded ? 240.0 : 80.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 1.0],
              colors: [
                Color(0xFF3D1166),
                Color(0xFF1A0A2E),
                Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: isExpanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Top Section: Hamburger & Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: theme.textColor,
                        size: 24,
                      ),
                      onPressed: onToggle,
                      splashRadius: 24,
                      tooltip: 'Toggle Sidebar',
                    ),
                    if (isExpanded)
                      Expanded(
                        child: ClipRect(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                _buildBrandIcon(accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  'SONIQO',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Primary Navigation (Fixed)
              _buildMenuItem(Icons.home_filled, 'Home', accentColor, theme),
              _buildMenuItem(Icons.explore_outlined, 'Explore', accentColor, theme),
              _buildMenuItem(
                Icons.library_music_outlined,
                'Library',
                accentColor,
                theme,
              ),

              const SizedBox(height: 20),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24.0 : 16.0),
                child: Divider(
                  color: accentColor.withValues(alpha: 0.35),
                  height: 1,
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Navigation Header (Fixed)
              if (isExpanded)
                ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28.0,
                        vertical: 6.0,
                      ),
                      child: Text(
                        'YOUR MUSIC',
                        style: TextStyle(
                          color: theme.textSecondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Scrollable Menu Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: isExpanded
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      _buildMenuItem(
                        Icons.favorite_border,
                        'Favourite',
                        accentColor,
                        theme,
                      ),
                      _buildMenuItem(
                        Icons.history,
                        'Play History',
                        accentColor,
                        theme,
                      ),
                      _buildMenuItem(
                        Icons.download_for_offline,
                        'Downloaded',
                        accentColor,
                        theme,
                      ),
                      _buildMenuItem(
                        Icons.add_circle_outline_rounded,
                        'Add Song',
                        accentColor,
                        theme,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Settings Item (always visible at bottom)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 24.0 : 16.0,
                  vertical: 8.0,
                ),
                child: Divider(
                  color: accentColor.withValues(alpha: 0.4),
                  height: 1,
                ),
              ),
              _buildMenuItem(Icons.settings_outlined, 'Settings', accentColor, theme),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandIcon(Color accentColor) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: ClipRect(
              clipper: _HalfClipper(topHalf: false),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFFCCCCCC),
                size: 28,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 2, // Shift right slightly
            child: ClipRect(
              clipper: _HalfClipper(topHalf: true),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFFCCCCCC),
                size: 28,
              ),
            ),
          ),
          Positioned(
            top: 13,
            left: 6,
            child: Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color accentColor, AppThemeExtension theme) {
    bool isSelected = selectedMenu == label;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onMenuSelected(label),
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.borderColor,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 14.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.textSecondaryColor,
                  size: 20,
                ),
                if (isExpanded)
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textSecondaryColor,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  final bool topHalf;
  _HalfClipper({required this.topHalf});

  @override
  Rect getClip(Size size) {
    if (topHalf) {
      return Rect.fromLTWH(0, 0, size.width, size.height / 2 + 0.5);
    } else {
      return Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);
    }
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
