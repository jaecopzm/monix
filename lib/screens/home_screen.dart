import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_transaction_bottom_sheet.dart';
import 'notifications_bottom_sheet.dart';
import 'package:monixx/widgets/transaction_item.dart';
import '../models/transaction.dart';
import '../models/app_notification.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../services/notification_data_service.dart';
import '../services/haptic_service.dart';
import '../widgets/budget_section.dart';
import '../widgets/empty_state.dart';
import '../widgets/insights_card.dart';
import '../theme/app_theme.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';
import 'recurring_transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String? initialType)? onAddTransaction;
  final VoidCallback? onThemeChanged;
  final VoidCallback? onNavigateToStats;
  const HomeScreen({
    super.key,
    this.onAddTransaction,
    this.onThemeChanged,
    this.onNavigateToStats,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final SettingsService _settings = SettingsService();
  final NotificationDataService _notificationService = NotificationDataService();
  final ScrollController _scrollController = ScrollController();

  List<Transaction> _transactions = [];
  double _balance = 0.0;
  double _income = 0.0;
  double _expenses = 0.0;
  bool _isLoading = true;
  int _unreadNotifications = 0;

  String _username = 'User';
  String _currencySymbol = '\$';

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'ZMW': 'K',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotificationCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSettings(), _loadTransactions()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount();
    setState(() => _unreadNotifications = count);
    
    // Generate sample notifications if none exist (for testing)
    final all = await _notificationService.getAll();
    if (all.isEmpty) {
      await _generateSampleNotifications();
      final newCount = await _notificationService.getUnreadCount();
      setState(() => _unreadNotifications = newCount);
    }
  }

  Future<void> _generateSampleNotifications() async {
    await _notificationService.add(AppNotification(
      title: 'Netflix Payment Due',
      message: 'Your Netflix subscription of $_currencySymbol 15.99 is due tomorrow',
      type: 'recurring_due',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));
    
    await _notificationService.add(AppNotification(
      title: 'Budget Alert',
      message: 'You\'ve spent 85% of your Food budget this month',
      type: 'budget_alert',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ));
    
    await _notificationService.add(AppNotification(
      title: 'Goal Achieved! 🎉',
      message: 'Congratulations! You\'ve reached your savings goal',
      type: 'goal_achieved',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ));
  }

  Future<void> _loadSettings() async {
    final username = await _settings.getUsername();
    final currency = await _settings.getCurrency();
    setState(() {
      _username = username;
      _currencySymbol = _currencySymbols[currency] ?? '\$';
    });
  }

  Future<void> _loadTransactions() async {
    final transactions = await _dataService.getTransactions();
    setState(() {
      _transactions = transactions;
      _calculateBalance();
    });
  }

  void _calculateBalance() {
    _income = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    _expenses = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    _balance = _income - _expenses;
  }

  void _editTransaction(Transaction transaction) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTransactionBottomSheet(transactionToEdit: transaction),
    ).then((updated) {
      if (updated == true) {
        _loadTransactions();
      }
    });
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticService.heavy();
      await _dataService.deleteTransaction(transaction);
      await _loadTransactions();
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol${amount.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEnhancedBalanceCard(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                      EnhancedInsightsCard(
                        transactions: _transactions,
                        currencySymbol: _currencySymbol,
                      ),
                      const SizedBox(height: 12),
                      const BudgetSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecentTransactionsHeader(),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyState(
                      svgPath: 'assets/svgs/no-transactions.svg',
                      title: 'No Transactions Yet',
                      message:
                          'Start tracking your finances by adding your first transaction',
                      actionText: 'Add Transaction',
                      onAction: () {
                        HapticService.light();
                        widget.onAddTransaction?.call('expense');
                      },
                    ),
                  ),
                )
              else
                _buildGroupedTransactions(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Bottom padding
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final greetingEmoji = hour < 12
        ? '☀️'
        : hour < 17
        ? '👋'
        : '🌙';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting $greetingEmoji',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _unreadNotifications > 0,
                  label: Text(_unreadNotifications.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  HapticService.light();
                  _showNotificationsSheet();
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ProfileScreen(
                        onThemeChanged: widget.onThemeChanged,
                        onNavigateToStats: widget.onNavigateToStats,
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).cardColor,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildEnhancedBalanceCard() {
    final isPositive = _balance >= 0;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        // Could toggle between different time periods
      },
      child:
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                  _formatCurrency(_balance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideX(
                                  begin: -0.2,
                                  end: 0,
                                  curve: Curves.easeOut,
                                ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceItem(
                            'Income',
                            _income,
                            Icons.arrow_downward,
                            Colors.greenAccent,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildBalanceItem(
                            'Expenses',
                            _expenses,
                            Icons.arrow_upward,
                            Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline,
        label: 'Income',
        color: Colors.green,
        onTap: () {
          HapticService.light();
          widget.onAddTransaction?.call('income');
        },
      ),
      _QuickAction(
        icon: Icons.remove_circle_outline,
        label: 'Expense',
        color: Colors.red,
        onTap: () {
          HapticService.light();
          widget.onAddTransaction?.call('expense');
        },
      ),
      _QuickAction(
        icon: Icons.repeat,
        label: 'Recurring',
        color: Colors.blue,
        onTap: () {
          HapticService.light();
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const RecurringTransactionsScreen(),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.analytics_outlined,
        label: 'Analytics',
        color: Colors.purple,
        onTap: () {
          HapticService.light();
          widget.onNavigateToStats?.call();
        },
      ),
    ];

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildQuickActionCard(action, index);
        },
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildQuickActionCard(_QuickAction action, int index) {
    return GestureDetector(
          onTap: action.onTap,
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: action.color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.3, end: 0);
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Recent Transactions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_transactions.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              HapticService.selection();
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TransactionsScreen(),
                ),
              ).then((_) => _loadTransactions());
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('See All'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildGroupedTransactions() {
    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in _transactions.take(10)) {
      final dateKey = _formatDateKey(transaction.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entries = groupedTransactions.entries.toList();
        final entry = entries[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...entry.value.map(
              (transaction) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Dismissible(
                  key: Key(transaction.id!),
                  background: _buildDismissBackground(
                    Alignment.centerLeft,
                    Colors.blue,
                  ),
                  secondaryBackground: _buildDismissBackground(
                    Alignment.centerRight,
                    Colors.red,
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      HapticService.heavy();
                      final confirmed = await _showDeleteConfirmation();
                      return confirmed;
                    } else {
                      HapticService.light();
                      _editTransaction(transaction);
                      return false;
                    }
                  },
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await _deleteTransaction(transaction);
                    }
                  },
                  child: GestureDetector(
                    onTap: () => _editTransaction(transaction),
                    child: EnhancedTransactionItem(
                      transaction: transaction,
                      currency: _currencySymbol,
                      onEdit: () => _editTransaction(transaction),
                      onDelete: () => _deleteTransaction(transaction),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
      }, childCount: groupedTransactions.length),
    );
  }

  Widget _buildDismissBackground(Alignment alignment, Color color) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: Icon(isLeft ? Icons.edit : Icons.delete, color: color),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showNotificationsSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsBottomSheet(),
    );
    if (result == true) {
      _loadNotificationCount();
    }
  }

  Widget _buildShimmerCard() {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
