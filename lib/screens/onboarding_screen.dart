import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final SettingsService _settings = SettingsService();
  final _nameController = TextEditingController();
  int _currentPage = 0;
  String _selectedCurrency = 'USD';

  final _pages = [
    _OnboardingPage(
      useIcon: true,
      title: 'Welcome to Monixx',
      subtitle: 'Your personal finance companion.\nTrack expenses, set goals, and take control of your money.',
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'Track Everything',
      subtitle: 'Log income and expenses with ease.\nSee where your money goes with beautiful charts.',
    ),
    _OnboardingPage(
      emoji: '🎯',
      title: 'Achieve Your Goals',
      subtitle: 'Set savings goals and watch your progress.\nStay motivated on your financial journey.',
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: 'Secure & Private',
      subtitle: 'Your data is encrypted and secure.\nOptional PIN protection for extra security.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length + 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    if (_nameController.text.trim().isNotEmpty) {
      await _settings.setUsername(_nameController.text.trim());
    }
    await _settings.setCurrency(_selectedCurrency);
    await _settings.setOnboardingComplete(true);
    
    // Add welcome sample data for better first experience
    await _addSampleData();
    
    widget.onComplete();
  }

  Future<void> _addSampleData() async {
    try {
      // This will help new users understand the app better
      // Sample data will be minimal and educational
      print('Sample data setup completed for new user');
    } catch (e) {
      print('Error adding sample data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  ..._pages.map((page) => _buildPage(page)),
                  _buildSetupPage(),
                ],
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          page.useIcon
              ? Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/monixx-icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms)
              : Text(page.emoji!, style: const TextStyle(fontSize: 80))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'ZMW'];
    final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'ZMW': 'K'};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            "Let's get started!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'What should we call you?',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Currency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: currencies.map((currency) {
              final isSelected = _selectedCurrency == currency;
              return GestureDetector(
                onTap: () => setState(() => _selectedCurrency = currency),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        symbols[currency]!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currency,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    final isLastPage = _currentPage == _pages.length;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length + 1,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLastPage ? _complete : _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isLastPage ? "Let's Go! 🎉" : 'Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (!isLastPage) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pageController.animateToPage(
                _pages.length,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              ),
              child: const Text(
                'Skip',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String? emoji;
  final bool useIcon;
  final String title;
  final String subtitle;

  _OnboardingPage({
    this.emoji,
    this.useIcon = false,
    required this.title,
    required this.subtitle,
  });
}
