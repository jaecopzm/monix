import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:monixx/widgets/transaction_item.dart';
import 'add_transaction_bottom_sheet.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../services/haptic_service.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final DataService _dataService = DataService();
  final SettingsService _settings = SettingsService();
  List<Transaction> _transactions = [];
  String _currencySymbol = '\$';
  String _filter = 'all';
  String _timeFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _dataService.getTransactions();
    final categories = await _dataService.getCategories();
    final currency = await _settings.getCurrency();
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _currencySymbol =
          {
            'USD': '\$',
            'EUR': '€',
            'GBP': '£',
            'JPY': '¥',
            'ZMW': 'K',
          }[currency] ??
          '\$';
    });
  }

  List<Transaction> get _filteredTransactions {
    var list = _transactions;

    // Filter by type
    if (_filter != 'all') {
      list = list.where((t) => t.type == _filter).toList();
    }

    // Filter by time
    final now = DateTime.now();
    switch (_timeFilter) {
      case 'Today':
        list = list
            .where(
              (t) =>
                  t.date.year == now.year &&
                  t.date.month == now.month &&
                  t.date.day == now.day,
            )
            .toList();
        break;
      case 'Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        list = list.where((t) => t.date.isAfter(weekAgo)).toList();
        break;
      case 'Month':
        list = list
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
        break;
      case 'Year':
        list = list.where((t) => t.date.year == now.year).toList();
        break;
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (t) =>
                t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (t.description?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    return list;
  }

  void _showEditSheet(Transaction transaction) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddTransactionBottomSheet(transactionToEdit: transaction),
    ).then((updated) {
      if (updated == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('All Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Time filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTimeFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('Today'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('Week'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('Month'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('Year'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Type filter chips
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income', 'income'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expense', 'expense'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? EmptyState(
                    emoji: _searchQuery.isNotEmpty ? '🔍' : '💸',
                    title: _searchQuery.isNotEmpty
                        ? 'No Results Found'
                        : 'No Transactions Yet',
                    message: _searchQuery.isNotEmpty
                        ? 'Try adjusting your search or filters'
                        : 'Start tracking your finances by adding transactions',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final t = _filteredTransactions[index];
                      return Dismissible(
                        key: Key(t.id!),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Transaction?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          HapticService.heavy();
                          await _dataService.deleteTransaction(t);
                          await _loadData();
                        },
                        child: GestureDetector(
                          onTap: () => _showEditSheet(t),
                          child: EnhancedTransactionItem(
                            transaction: t,
                            currency: _currencySymbol,
                            onDelete: () async {
                              HapticService.heavy();
                              await _dataService.deleteTransaction(t);
                              await _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildTimeFilterChip(String label) {
    final isSelected = _timeFilter == label;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() => _timeFilter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}
