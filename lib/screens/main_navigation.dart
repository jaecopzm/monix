import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'goals/goals_screen.dart';
import 'premium_features_screen.dart';
import 'add_transaction_bottom_sheet.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  const MainNavigation({super.key, this.onThemeChanged});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _fabAnimationController;
  late final AnimationController _navAnimationController;
  late final Animation<double> _fabScaleAnimation;
  late final Animation<double> _fabRotationAnimation;
  Key _refreshKey = UniqueKey();

  List<Widget> get _screens => [
    HomeScreen(
      key: _refreshKey,
      onAddTransaction: _showAddTransactionSheet,
      onThemeChanged: widget.onThemeChanged,
      onNavigateToStats: () => _onNavItemTapped(1),
    ),
    StatisticsScreen(key: ValueKey('stats_$_refreshKey')),
    GoalsScreen(key: ValueKey('goals_$_refreshKey')),
    PremiumFeaturesScreen(onNavigateToStats: () => _onNavItemTapped(1)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // FAB animation setup
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabRotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Nav bar animation
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      HapticService.light();

      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showAddTransactionSheet([String? initialType]) {
    HapticService.medium();

    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTransactionBottomSheet(initialType: initialType ?? 'expense'),
    ).then((result) {
      if (result == true && mounted) {
        setState(() => _refreshKey = UniqueKey());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure system UI stays consistent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.white,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark 
            ? Brightness.dark 
            : Brightness.light,
      ),
    );

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          HapticService.light();
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomAppBar(
          color: Theme.of(context).cardColor,
          elevation: 0,
          notchMargin: 10,
          height: 80,
          padding: EdgeInsets.zero,
          shape: const CircularNotchedRectangle(),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Stats',
                    index: 1,
                  ),
                  // Spacer for FAB
                  const SizedBox(width: 56),
                  _buildNavItem(
                    icon: Icons.flag_outlined,
                    activeIcon: Icons.flag_rounded,
                    label: 'Goals',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.workspace_premium_outlined,
                    activeIcon: Icons.workspace_premium,
                    label: 'Premium',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: RotationTransition(
        turns: _fabRotationAnimation,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(
                  red: (AppTheme.primaryColor.r * 0.85).clamp(0, 1.0),
                  green: (AppTheme.primaryColor.g * 0.85).clamp(0, 1.0),
                  blue: (AppTheme.primaryColor.b * 0.85).clamp(0, 1.0),
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAddTransactionSheet,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, size: 34, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTapped(index),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      width: isSelected ? 52 : 0,
                      height: isSelected ? 32 : 0,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10.5,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: isSelected ? -0.2 : -0.1,
                    height: 1.2,
                  ),
                  child: Text(label, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
