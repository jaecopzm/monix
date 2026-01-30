import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/database_helper.dart';
import '../screens/budget_management_screen.dart';
import '../theme/app_theme.dart';

class BudgetSection extends StatefulWidget {
  const BudgetSection({super.key});

  @override
  State<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<BudgetSection> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Budget> _budgets = [];
  Map<String, double> _spending = {};
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await _dbHelper.getBudgets(_currentMonth);
    final Map<String, double> spending = {};

    for (var budget in budgets) {
      final spent = await _dbHelper.getCategorySpending(
        budget.category,
        _currentMonth,
      );
      spending[budget.category] = spent;
    }

    setState(() {
      _budgets = budgets;
      _spending = spending;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_budgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budgets', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const BudgetManagementScreen(),
                  ),
                );
              },
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._budgets.map((budget) => _buildBudgetCard(budget)),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _spending[budget.category] ?? 0.0;
    final progress = (spent / budget.amount).clamp(0.0, 1.0);
    final isOverBudget = spent > budget.amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                budget.category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${spent.toStringAsFixed(0)} / \$${budget.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isOverBudget
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
              ),
            ),
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 4),
            Text(
              'Over budget by \$${(spent - budget.amount).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }
}
