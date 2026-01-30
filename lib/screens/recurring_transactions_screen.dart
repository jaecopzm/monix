import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../services/haptic_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import 'add_recurring_transaction_sheet.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final RecurringTransactionService _service = RecurringTransactionService();
  final SettingsService _settings = SettingsService();
  List<RecurringTransaction> _recurring = [];
  List<RecurringTransaction> _filteredRecurring = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, active, paused
  String _sortBy = 'date'; // date, amount, name
  String _currencySymbol = '\$';

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await _settings.getCurrency();
    setState(() {
      _currencySymbol = _currencySymbols[currency] ?? '\$';
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _recurring = await _service.getAll();
    _applyFiltersAndSort();
    setState(() => _isLoading = false);
  }

  void _applyFiltersAndSort() {
    _filteredRecurring = _recurring.where((r) {
      if (_filterStatus == 'active') return r.isActive;
      if (_filterStatus == 'paused') return !r.isActive;
      return true;
    }).toList();

    _filteredRecurring.sort((a, b) {
      switch (_sortBy) {
        case 'amount':
          return b.amount.compareTo(a.amount);
        case 'name':
          return a.title.compareTo(b.title);
        case 'date':
        default:
          return _service.getNextOccurrence(a).compareTo(
            _service.getNextOccurrence(b),
          );
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
            : const Color(0xFFF5F5F5),
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark 
            ? Brightness.dark 
            : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFFF5F5F5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticService.light();
              _showAddSheet();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recurring.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.repeat,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No recurring transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add subscriptions and recurring bills',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildSummaryCard(),
                _buildFilterSort(),
                Expanded(
                  child: _filteredRecurring.isEmpty
                      ? Center(
                          child: Text(
                            'No matching transactions',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecurring.length,
                          itemBuilder: (context, index) {
                            final r = _filteredRecurring[index];
                            return _buildRecurringCard(r, index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final active = _recurring.where((r) => r.isActive).toList();
    final monthlyTotal = active.fold<double>(0, (sum, r) {
      switch (r.frequency) {
        case 'daily':
          return sum + (r.amount * 30);
        case 'weekly':
          return sum + (r.amount * 4);
        case 'monthly':
          return sum + r.amount;
        case 'yearly':
          return sum + (r.amount / 12);
        default:
          return sum;
      }
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Cost',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currencySymbol${monthlyTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildCompactStat('${active.length}', 'Active'),
              const SizedBox(width: 12),
              _buildCompactStat(
                '${_recurring.length - active.length}',
                'Paused',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSort() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paused', 'paused'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppTheme.primaryColor),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applyFiltersAndSort();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Next Payment')),
              const PopupMenuItem(value: 'amount', child: Text('Amount')),
              const PopupMenuItem(value: 'name', child: Text('Name')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() {
          _filterStatus = value;
          _applyFiltersAndSort();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringCard(RecurringTransaction r, int index) {
    final iconType = CategoryIcons.hasSvgIcon(r.category, type: 'subscription')
        ? 'subscription'
        : r.type;
    final brandColor = CategoryIcons.getBrandColor(r.category);
    final cardColor = brandColor ?? (r.type == 'income' ? Colors.green : Colors.red);

    return GestureDetector(
      onTap: () => _showEditSheet(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor.withValues(alpha: 0.05),
              Theme.of(context).cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: r.isActive
                ? cardColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColor.withValues(alpha: 0.2),
                          cardColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CategoryIcons.getIcon(
                      r.category,
                      size: 28,
                      type: iconType,
                      color: brandColor == null ? cardColor : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getFrequencyText(r.frequency),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cardColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              r.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_currencySymbol${r.amount.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: r.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.isActive ? 'Active' : 'Paused',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: r.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next: ${_getNextDate(r)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          r.isActive ? Icons.pause_circle : Icons.play_circle,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        onPressed: () async {
                          HapticService.light();
                          await _service.toggleActive(r);
                          await _loadData();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                        onPressed: () => _deleteRecurring(r),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn()
          .slideY(begin: 0.2, end: 0),
    );
  }

  String _getNextDate(RecurringTransaction r) {
    final next = _service.getNextOccurrence(r);
    final now = DateTime.now();
    final diff = next.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${next.day}/${next.month}/${next.year}';
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  void _showAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRecurringTransactionSheet(),
    );
    if (result == true) await _loadData();
  }

  void _showEditSheet(RecurringTransaction recurring) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRecurringTransactionSheet(recurring: recurring),
    );
    if (result == true) await _loadData();
  }

  Future<void> _deleteRecurring(RecurringTransaction r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text('Are you sure you want to delete "${r.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticService.heavy();
      await _service.delete(r.id!);
      await _loadData();
    }
  }
}
