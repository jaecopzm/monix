import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/haptic_service.dart';
import 'recurring_transactions_screen.dart';
import 'accounts_screen.dart';
import 'notification_settings_screen.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  final VoidCallback? onNavigateToStats;
  const PremiumFeaturesScreen({super.key, this.onNavigateToStats});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _isYearly = true;
  
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.auto_awesome,
      'title': 'AI Financial Insights',
      'description': 'Get personalized AI-powered financial advice',
      'color': Colors.purple,
      'premium': true,
    },
    {
      'icon': Icons.repeat,
      'title': 'Recurring Transactions',
      'description': 'Never miss a bill or subscription payment',
      'color': Colors.blue,
      'premium': true,
      'screen': () => const RecurringTransactionsScreen(),
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Advanced Analytics',
      'description': 'Deep insights with PDF export',
      'color': Colors.indigo,
      'premium': true,
    },
    {
      'icon': Icons.account_balance_wallet,
      'title': 'Multiple Accounts',
      'description': 'Track unlimited accounts separately',
      'color': Colors.green,
      'premium': true,
      'screen': () => const AccountsScreen(),
    },
    {
      'icon': Icons.notifications_active,
      'title': 'Smart Notifications',
      'description': 'Budget alerts and goal reminders',
      'color': Colors.orange,
      'premium': true,
      'screen': () => const NotificationSettingsScreen(),
    },
    {
      'icon': Icons.cloud_sync,
      'title': 'Cloud Sync',
      'description': 'Sync across all your devices',
      'color': Colors.cyan,
      'premium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildPricingSection(),
            _buildFeaturesSection(),
            _buildComparisonSection(),
            _buildCTASection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.secondaryColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 32),
            ).animate().scale(delay: 200.ms),
            
            const SizedBox(height: 16),
            
            Text(
              'Monixx Premium',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideY(begin: 0.3),
            
            const SizedBox(height: 8),
            
            Text(
              'Unlock the full potential of your financial management',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
            
            const SizedBox(height: 24),
            
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _buildBenefitChip('🚀', 'Boost Productivity'),
                _buildBenefitChip('💡', 'Smart Insights'),
                _buildBenefitChip('🔒', 'Premium Support'),
              ],
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption('Monthly', !_isYearly),
                  _buildToggleOption('Yearly', _isYearly),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pricing Cards
            Row(
              children: [
                Expanded(child: _buildPricingCard(false)),
                const SizedBox(width: 16),
                Expanded(child: _buildPricingCard(true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _isYearly = text == 'Yearly');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(bool isPremium) {
    final monthlyPrice = isPremium ? 9.99 : 0.0;
    final yearlyPrice = isPremium ? 79.99 : 0.0;
    final currentPrice = _isYearly ? yearlyPrice : monthlyPrice;
    final savings = _isYearly && isPremium ? ((monthlyPrice * 12) - yearlyPrice) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPremium ? AppTheme.primaryColor : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
          width: isPremium ? 2 : 1,
        ),
        boxShadow: isPremium ? [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          Text(
            isPremium ? 'Premium' : 'Free',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPremium ? Colors.white : null,
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (isPremium) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  currentPrice.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isYearly ? '/year' : '/month',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            if (_isYearly && savings > 0)
              Text(
                'Save \$${savings.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ] else ...[
            const Text(
              '\$0',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Forever',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleSubscription(isPremium),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? Colors.white : AppTheme.primaryColor,
                foregroundColor: isPremium ? AppTheme.primaryColor : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isPremium ? 'Start Free Trial' : 'Current Plan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (isPremium ? 100 : 0).ms).fadeIn().scale();
  }

  Widget _buildFeaturesSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(feature, index);
          },
          childCount: _features.length,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        if (feature['screen'] != null) {
          final screenBuilder = feature['screen'] as Widget Function();
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => screenBuilder()),
          );
        } else if (feature['title'] == 'Advanced Analytics') {
          widget.onNavigateToStats?.call();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (feature['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: feature['color'] as Color,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (feature['premium'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'] as String,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: feature['color'] as Color,
              size: 16,
            ),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.2),
    );
  }

  Widget _buildComparisonSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          children: [
            Text(
              'Free vs Premium',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildComparisonRow('Basic expense tracking', true, true),
            _buildComparisonRow('AI financial insights', false, true),
            _buildComparisonRow('Advanced analytics', false, true),
            _buildComparisonRow('Unlimited accounts', false, true),
            _buildComparisonRow('Cloud sync', false, true),
            _buildComparisonRow('Priority support', false, true),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildComparisonRow(String feature, bool free, bool premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Icon(
              free ? Icons.check : Icons.close,
              color: free ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          Expanded(
            child: Icon(
              premium ? Icons.check : Icons.close,
              color: premium ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              '🚀',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ready to upgrade?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join thousands of users managing their finances smarter',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSubscription(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start 7-Day Free Trial',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cancel anytime • No commitment',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(),
    );
  }

  void _handleSubscription(bool isPremium) {
    HapticService.medium();
    
    if (isPremium) {
      // TODO: Implement subscription logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Premium subscription coming soon!'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
