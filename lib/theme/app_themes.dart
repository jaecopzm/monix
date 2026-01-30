import 'package:flutter/material.dart';

class AppThemes {
  // Original Monixx Theme
  static const monixxPrimary = Color(0xFF6C63FF);
  static const monixxSecondary = Color(0xFF4ECDC4);
  static const monixxAccent = Color(0xFFFFE66D);

  // Ocean Theme
  static const oceanPrimary = Color(0xFF0077BE);
  static const oceanSecondary = Color(0xFF00A8CC);
  static const oceanAccent = Color(0xFF40E0D0);

  // Forest Theme
  static const forestPrimary = Color(0xFF2E7D32);
  static const forestSecondary = Color(0xFF4CAF50);
  static const forestAccent = Color(0xFF8BC34A);

  // Sunset Theme
  static const sunsetPrimary = Color(0xFFFF6B35);
  static const sunsetSecondary = Color(0xFFFF8E53);
  static const sunsetAccent = Color(0xFFFFB74D);

  // Purple Theme
  static const purplePrimary = Color(0xFF7B1FA2);
  static const purpleSecondary = Color(0xFF9C27B0);
  static const purpleAccent = Color(0xFFBA68C8);

  // Rose Theme
  static const rosePrimary = Color(0xFFE91E63);
  static const roseSecondary = Color(0xFFF06292);
  static const roseAccent = Color(0xFFFF80AB);

  static const successColor = Color(0xFF4CAF50);
  static const errorColor = Color(0xFFF44336);
  static const warningColor = Color(0xFFFF9800);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);

  static final cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static ThemeData getTheme(String themeName, bool isDark) {
    final colors = _getThemeColors(themeName);
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
      ),
    );
  }

  static Map<String, Color> _getThemeColors(String themeName) {
    switch (themeName) {
      case 'ocean':
        return {
          'primary': oceanPrimary,
          'secondary': oceanSecondary,
          'accent': oceanAccent,
        };
      case 'forest':
        return {
          'primary': forestPrimary,
          'secondary': forestSecondary,
          'accent': forestAccent,
        };
      case 'sunset':
        return {
          'primary': sunsetPrimary,
          'secondary': sunsetSecondary,
          'accent': sunsetAccent,
        };
      case 'purple':
        return {
          'primary': purplePrimary,
          'secondary': purpleSecondary,
          'accent': purpleAccent,
        };
      case 'rose':
        return {
          'primary': rosePrimary,
          'secondary': roseSecondary,
          'accent': roseAccent,
        };
      case 'monixx':
      default:
        return {
          'primary': monixxPrimary,
          'secondary': monixxSecondary,
          'accent': monixxAccent,
        };
    }
  }

  static List<Map<String, dynamic>> getAvailableThemes() {
    return [
      {
        'name': 'monixx',
        'displayName': 'Monixx',
        'description': 'Original purple theme',
        'primaryColor': monixxPrimary,
        'gradient': [monixxPrimary, monixxSecondary],
      },
      {
        'name': 'ocean',
        'displayName': 'Ocean',
        'description': 'Cool blue waters',
        'primaryColor': oceanPrimary,
        'gradient': [oceanPrimary, oceanSecondary],
      },
      {
        'name': 'forest',
        'displayName': 'Forest',
        'description': 'Natural green vibes',
        'primaryColor': forestPrimary,
        'gradient': [forestPrimary, forestSecondary],
      },
      {
        'name': 'sunset',
        'displayName': 'Sunset',
        'description': 'Warm orange glow',
        'primaryColor': sunsetPrimary,
        'gradient': [sunsetPrimary, sunsetSecondary],
      },
      {
        'name': 'purple',
        'displayName': 'Purple',
        'description': 'Deep purple elegance',
        'primaryColor': purplePrimary,
        'gradient': [purplePrimary, purpleSecondary],
      },
      {
        'name': 'rose',
        'displayName': 'Rose',
        'description': 'Romantic pink tones',
        'primaryColor': rosePrimary,
        'gradient': [rosePrimary, roseSecondary],
      },
    ];
  }
}
