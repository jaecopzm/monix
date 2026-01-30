import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../services/data_service.dart';
import '../services/security_service.dart';
import '../services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'recurring_transactions_screen.dart';
import 'accounts_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final VoidCallback? onNavigateToStats;
  const ProfileScreen({super.key, this.onThemeChanged, this.onNavigateToStats});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SettingsService _settings = SettingsService();
  final DataService _dataService = DataService();
  final SecurityService _security = SecurityService();
  final AuthService _authService = AuthService();
  String _username = 'User';
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _canUseBiometrics = false;
  String _selectedCurrency = 'USD';
  int _transactionCount = 0;
  int _categoryCount = 0;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadSettings();
    _loadStats();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canUse = await _security.canUseBiometrics();
    final enabled = await _security.isBiometricsEnabled();
    setState(() {
      _canUseBiometrics = canUse;
      _biometricsEnabled = enabled;
    });
  }

  Future<void> _loadStats() async {
    final transactions = await _dataService.getTransactions();
    final categories = await _dataService.getCategories();
    setState(() {
      _transactionCount = transactions.length;
      _categoryCount = categories.length;
    });
  }

  Future<void> _loadSettings() async {
    final username = await _settings.getUsername();
    final darkMode = await _settings.getDarkMode();
    final currency = await _settings.getCurrency();
    setState(() {
      _username = username;
      _darkMode = darkMode;
      _selectedCurrency = currency;
    });
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _username);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _settings.setUsername(controller.text.trim());
                  if (mounted) {
                    setState(() => _username = controller.text.trim());
                  }
                  navigator.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyPicker() {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'ZMW'];
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'ZMW': 'K',
    };

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...currencies.map(
                (currency) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      symbols[currency]!,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(currency),
                  trailing: _selectedCurrency == currency
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                  onTap: () async {
                    await _settings.setCurrency(currency);
                    setState(() => _selectedCurrency = currency);
                    navigator.pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting your financial data...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _setupPasscode() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Set Passcode'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter 4-digit passcode',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.length == 4) {
                  await _security.setPasscode(controller.text);
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Passcode set successfully'),
                      ),
                    );
                  } else {
                    navigator.pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to sync data')),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final syncService = SyncService(uid: user.uid);
      await syncService.fullSync();
      setState(() => _lastSyncTime = DateTime.now());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Data synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'ZMW': 'K',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop()) ...[
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).cardColor,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ).animate().fadeIn(duration: 400.ms),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).cardColor,
                            elevation: 2,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildProfileHeader(),
                    const SizedBox(height: 32),
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSettingTile(
                    'Dark Mode',
                    'Switch to ${_darkMode ? "light" : "dark"} theme',
                    Icons.dark_mode_outlined,
                    Switch.adaptive(
                      value: _darkMode,
                      onChanged: (value) async {
                        await _settings.setDarkMode(value);
                        setState(() => _darkMode = value);
                        widget.onThemeChanged?.call();
                      },
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    delay: 0,
                  ),
                  _buildSettingTile(
                    'Notifications',
                    _notificationsEnabled ? 'Enabled' : 'Disabled',
                    Icons.notifications_outlined,
                    Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    delay: 100,
                  ),
                  _buildSettingTile(
                    'Currency',
                    '$_selectedCurrency (${currencySymbols[_selectedCurrency]})',
                    Icons.attach_money_outlined,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 200,
                    onTap: _showCurrencyPicker,
                  ),
                  _buildSettingTile(
                    'Notifications',
                    'Manage alerts and reminders',
                    Icons.notifications_outlined,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 225,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    'Passcode Lock',
                    'Set a 4-digit passcode',
                    Icons.lock_outline,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 150,
                    onTap: _setupPasscode,
                  ),
                  if (_canUseBiometrics)
                    _buildSettingTile(
                      'Biometric Authentication',
                      'Use fingerprint or face ID',
                      Icons.fingerprint,
                      Switch.adaptive(
                        value: _biometricsEnabled,
                        onChanged: (value) async {
                          await _security.setBiometricsEnabled(value);
                          setState(() => _biometricsEnabled = value);
                        },
                        activeThumbColor: AppTheme.primaryColor,
                      ),
                      delay: 175,
                    ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Data & Privacy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    'Sync Data',
                    _lastSyncTime != null
                        ? 'Last synced: ${_formatSyncTime(_lastSyncTime!)}'
                        : 'Sync your data across devices',
                    Icons.sync,
                    _isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 250,
                    onTap: _isSyncing ? null : _syncData,
                  ),
                  _buildSettingTile(
                    'Export Data',
                    'Download your financial data',
                    Icons.download_outlined,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 300,
                    onTap: _exportData,
                  ),
                  _buildSettingTile(
                    'Recurring Transactions',
                    'Manage subscriptions & bills',
                    Icons.repeat,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 350,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const RecurringTransactionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    'Advanced Analytics',
                    'Detailed reports & insights',
                    Icons.analytics_outlined,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 375,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToStats?.call();
                    },
                  ),
                  _buildSettingTile(
                    'Accounts & Wallets',
                    'Manage multiple accounts',
                    Icons.account_balance_wallet,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const AccountsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.privacy_tip_outlined,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 400,
                    onTap: () {},
                  ),
                  _buildSettingTile(
                    'Delete Account',
                    'Permanently delete your account',
                    Icons.delete_outline,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 500,
                    onTap: () {},
                    isDanger: true,
                  ),
                  _buildSettingTile(
                    'Sign Out',
                    'Logout of your account',
                    Icons.logout,
                    const Icon(Icons.chevron_right, color: Colors.grey),
                    delay: 550,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text(
                            'Are you sure you want to sign out? Your data will remain synced.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _authService.signOut();
                      }
                    },
                    isDanger: true,
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _currentUser?.displayName ?? _username;
    final email = _currentUser?.email ?? '';
    final photoUrl = _currentUser?.photoURL;
    final creationTime = _currentUser?.metadata.creationTime;
    final memberSince = creationTime != null
        ? 'Member since ${creationTime.year}'
        : 'Member since 2026';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_currentUser?.emailVerified == true)
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.white,
                            ),
                          if (_currentUser?.emailVerified == true)
                            const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      memberSince,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showEditNameDialog,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          if (_currentUser != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getProviderIcon(), size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Signed in with ${_getProviderName()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale();
  }

  IconData _getProviderIcon() {
    final providerId = _currentUser?.providerData.first.providerId;
    if (providerId == 'google.com') return Icons.g_mobiledata;
    if (providerId == 'password') return Icons.email_outlined;
    return Icons.person_outline;
  }

  String _getProviderName() {
    final providerId = _currentUser?.providerData.first.providerId;
    if (providerId == 'google.com') return 'Google';
    if (providerId == 'password') return 'Email';
    return 'Account';
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '$_transactionCount',
            'Transactions',
            Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '$_categoryCount',
            'Categories',
            Icons.category_outlined,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    Widget trailing, {
    int delay = 0,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger
                ? Colors.red.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDanger ? Colors.red : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDanger
                ? Colors.red
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: trailing,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2);
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
