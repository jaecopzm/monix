import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_themes.dart';
import '../services/settings_service.dart';
import '../services/haptic_service.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const ThemeSelectionScreen({super.key, this.onThemeChanged});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  final SettingsService _settings = SettingsService();
  String _selectedTheme = 'monixx';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final theme = await _settings.getTheme();
    final darkMode = await _settings.getDarkMode();
    setState(() {
      _selectedTheme = theme;
      _isDarkMode = darkMode;
    });
  }

  Future<void> _selectTheme(String themeName) async {
    HapticService.light();
    setState(() => _selectedTheme = themeName);
    await _settings.setTheme(themeName);
    widget.onThemeChanged?.call();
  }

  Future<void> _toggleDarkMode(bool value) async {
    HapticService.light();
    setState(() => _isDarkMode = value);
    await _settings.setDarkMode(value);
    widget.onThemeChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themes = AppThemes.getAvailableThemes();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppThemes.cardShadow],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: _isDarkMode ? Colors.amber : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                          style: const TextStyle(
                            color: AppThemes.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
            
            const SizedBox(height: 24),
            
            const Text(
              'Color Themes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Theme Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = _selectedTheme == theme['name'];
                
                return GestureDetector(
                  onTap: () => _selectTheme(theme['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? theme['primaryColor'] as Color
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: (theme['primaryColor'] as Color).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] : [AppThemes.cardShadow],
                    ),
                    child: Column(
                      children: [
                        // Gradient Preview
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: theme['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ).animate(onPlay: (c) => c.repeat())
                                      .scale(duration: 600.ms)
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        // Theme Info
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(19),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  theme['displayName'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? theme['primaryColor'] as Color : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  theme['description'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppThemes.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 100).ms).fadeIn().scale();
              },
            ),
          ],
        ),
      ),
    );
  }
}
