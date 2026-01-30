import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/settings_service.dart';
import '../services/data_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final DataService _dataService = DataService();
  List<Budget> _budgets = [];
  Map<String, double> _spending = {};
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final SettingsService _settings = SettingsService();
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
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await _dataService.getBudgets(_currentMonth);
    final currency = await _settings.getCurrency();
    final Map<String, double> spending = {};

    for (var budget in budgets) {
      final spent = await _dataService.getCategorySpending(
        budget.category,
        _currentMonth,
      );
      spending[budget.category] = spent;
    }

    setState(() {
      _budgets = budgets;
      _spending = spending;
      _currencySymbol = _currencySymbols[currency] ?? '\$';
    });
  }

  void _showAddBudgetSheet() async {
    HapticFeedback.lightImpact();
    final categories = await _dataService.getCategoriesByType('expense');
    if (!mounted) return;
    final amountController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Budget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setModalState(() => selectedCategory = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget Amount'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedCategory != null &&
                        amountController.text.isNotEmpty) {
                      await _dataService.insertBudget(
                        Budget(
                          category: selectedCategory!,
                          amount: double.parse(amountController.text),
                          month: _currentMonth,
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      if (mounted) {
                        _loadBudgets();
                      }
                    }
                  },
                  child: const Text('Add Budget'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            onPressed: _showAddBudgetSheet,
            icon: const Icon(Icons.add_circle),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: _budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets set',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first budget',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _budgets.length,
              itemBuilder: (context, index) =>
                  _buildBudgetCard(_budgets[index]),
            ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _spending[budget.category] ?? 0.0;
    final percentage = (spent / budget.amount * 100).clamp(0.0, 200.0);
    final progress = (spent / budget.amount).clamp(0.0, 1.0);
    final isOverBudget = spent > budget.amount;
    final isWarning = percentage >= 80 && !isOverBudget;
    final remaining = budget.amount - spent;

    Color getStatusColor() {
      if (isOverBudget) return AppTheme.errorColor;
      if (isWarning) return Colors.orange;
      return AppTheme.successColor;
    }

    String getStatusText() {
      if (isOverBudget) return 'Over budget!';
      if (isWarning) return 'Almost there';
      return 'On track';
    }

    return Dismissible(
      key: Key(budget.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        HapticService.heavy();
        await _dataService.deleteBudget(budget.id!);
        _loadBudgets();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            AppTheme.cardShadow,
            if (isWarning || isOverBudget)
              BoxShadow(
                color: getStatusColor().withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
          border: (isWarning || isOverBudget)
              ? Border.all(
                  color: getStatusColor().withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          children: [
            // Warning banner
            if (isWarning || isOverBudget)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverBudget ? Icons.error : Icons.warning,
                      color: getStatusColor(),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverBudget
                            ? 'Exceeded by $_currencySymbol${(-remaining).toStringAsFixed(2)}'
                            : '${percentage.toStringAsFixed(0)}% used',
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      getStatusText(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            // Budget details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_currencySymbol${spent.toStringAsFixed(0)} / $_currencySymbol${budget.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isOverBudget
                                ? 'Over by $_currencySymbol${(-remaining).toStringAsFixed(0)}'
                                : '$_currencySymbol${remaining.toStringAsFixed(0)} left',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(getStatusColor()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}% used',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.2),
    );
  }
}
