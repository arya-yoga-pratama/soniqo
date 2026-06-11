import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeColor _currentTheme = ThemeColor.purple;
  bool _isDarkMode = true;
  bool _isVideoBackgroundEnabled = true;
  bool _isInitialized = false;

  ThemeColor get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;
  bool get isVideoBackgroundEnabled => _isVideoBackgroundEnabled;
  bool get isInitialized => _isInitialized;

  // Get the current accent color
  Color get accentColor =>
      AppTheme.accentColors[_currentTheme] ??
      AppTheme.accentColors[ThemeColor.purple]!;

  // Get the theme data
  ThemeData get themeData => AppTheme.buildTheme(_currentTheme, isDarkMode: _isDarkMode);

  /// Initialize theme from SharedPreferences
  Future<void> initializeTheme() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColor = prefs.getString('theme_color') ?? 'purple';
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _isVideoBackgroundEnabled = prefs.getBool('is_video_background_enabled') ?? true;
      _currentTheme = AppTheme.stringToThemeColor(savedColor);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change the theme color and persist it
  Future<void> setThemeColor(ThemeColor color) async {
    if (_currentTheme == color) return;

    _currentTheme = color;
    notifyListeners();

    // Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_color', AppTheme.themeColorToString(color));
    } catch (e) {
      print('Error saving theme color: $e');
    }
  }

  /// Toggle dark mode and persist it
  Future<void> toggleDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', isDark);
    } catch (e) {
      print('Error saving dark mode state: $e');
    }
  }

  /// Toggle video background and persist it
  Future<void> toggleVideoBackground(bool isEnabled) async {
    if (_isVideoBackgroundEnabled == isEnabled) return;

    _isVideoBackgroundEnabled = isEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_video_background_enabled', isEnabled);
    } catch (e) {
      print('Error saving video background state: $e');
    }
  }

  /// Get theme color from string
  ThemeColor getThemeColorFromString(String colorName) {
    return AppTheme.stringToThemeColor(colorName);
  }

  /// Get string name of current theme
  String getCurrentThemeName() {
    return AppTheme.themeColorToString(_currentTheme);
  }
}
