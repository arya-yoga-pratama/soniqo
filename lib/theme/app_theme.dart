import 'package:flutter/material.dart';

enum ThemeColor { purple, blue, green }

class AppTheme {
  static const Map<ThemeColor, Color> accentColors = {
    ThemeColor.purple: Color(0xFF7C3AED),
    ThemeColor.blue: Color(0xFF2989D8),
    ThemeColor.green: Color(0xFF1B6E2E),
  };

  static const Map<ThemeColor, String> colorNames = {
    ThemeColor.purple: 'Purple',
    ThemeColor.blue: 'Blue',
    ThemeColor.green: 'Green',
  };

  static ThemeData buildTheme(ThemeColor themeColor, {bool isDarkMode = true}) {
    final accentColor =
        accentColors[themeColor] ?? accentColors[ThemeColor.purple]!;

    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7),
      primaryColor: accentColor,
      colorScheme: isDarkMode 
          ? ColorScheme.dark(
              primary: accentColor,
              surface: const Color(0xFF111111),
              onSurface: Colors.white,
            )
          : ColorScheme.light(
              primary: accentColor,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
      fontFamily: 'Segoe UI',
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension(
          accentColor: accentColor,
          backgroundColor: isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7),
          surfaceColor: isDarkMode ? const Color(0xFF181818) : Colors.white,
          borderColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          textColor: isDarkMode ? Colors.white : Colors.black87,
          textSecondaryColor: isDarkMode ? Colors.white54 : Colors.black54,
        ),
      ],
    );
  }

  // Get color for a specific theme
  static Color getAccentColor(ThemeColor theme) {
    return accentColors[theme] ?? accentColors[ThemeColor.purple]!;
  }

  // Convert string to ThemeColor
  static ThemeColor stringToThemeColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return ThemeColor.blue;
      case 'green':
        return ThemeColor.green;
      case 'purple':
      default:
        return ThemeColor.purple;
    }
  }

  // Convert ThemeColor to string
  static String themeColorToString(ThemeColor color) {
    return colorNames[color] ?? 'Purple';
  }
}

/// Custom theme extension for additional app-specific colors
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color textSecondaryColor;

  AppThemeExtension({
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.textSecondaryColor,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? borderColor,
    Color? textColor,
    Color? textSecondaryColor,
  }) {
    return AppThemeExtension(
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      borderColor: borderColor ?? this.borderColor,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;

    return AppThemeExtension(
      accentColor: Color.lerp(accentColor, other.accentColor, t) ?? accentColor,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t) ?? backgroundColor,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t) ?? surfaceColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      textColor: Color.lerp(textColor, other.textColor, t) ?? textColor,
      textSecondaryColor: Color.lerp(textSecondaryColor, other.textSecondaryColor, t) ?? textSecondaryColor,
    );
  }
}
