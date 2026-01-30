import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class EnhancedInsightsCard extends StatelessWidget {
  final List<Transaction> transactions;
  final String currencySymbol;

  const EnhancedInsightsCard({
    super.key,
    required this.transactions,
    required this.currencySymbol,
  });

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final normalizedNow = DateTime(now.year, now.month, now.day);

    int todayCount = 0;
    int weekCount = 0;
    double totalExpenses = 0.0;
    final Map<String, double> categoryTotals = {};
    final List<double> weeklySpending = List.filled(7, 0.0);

    for (var t in transactions) {
      if (t.type == 'expense') {
        totalExpenses += t.amount;
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;

        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        final daysDiff = normalizedNow.difference(tDate).inDays;
        if (daysDiff < 7 && daysDiff >= 0) {
          weeklySpending[6 - daysDiff] += t.amount;
        }
      }

      if (t.date.isAfter(todayStart)) todayCount++;
      if (t.date.isAfter(weekStart)) weekCount++;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = Map.fromEntries(sortedCategories.take(3));

    return {
      'todayCount': todayCount,
      'weekCount': weekCount,
      'totalExpenses': totalExpenses,
      'topCategories': topCategories,
      'weeklySpending': weeklySpending,
    };
  }

  String _formatCurrency(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStats();
    final topCategories = stats['topCategories'] as Map<String, double>;
    final totalExpenses = stats['totalExpenses'] as double;
    final todayCount = stats['todayCount'] as int;
    final weekCount = stats['weekCount'] as int;
    final weeklySpending = stats['weeklySpending'] as List<double>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Spending Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Today',
                  '$todayCount',
                  'transactions',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  context,
                  'This Week',
                  '$weekCount',
                  'transactions',
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekly Spending Chart
          _buildWeeklySpendingChart(context, weeklySpending),

          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            ...topCategories.entries.take(2).map((entry) {
              final percentage = (entry.value / totalExpenses * 100);
              return _buildCategoryBar(
                context,
                entry.key,
                entry.value,
                percentage,
              );
            }),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySpendingChart(
    BuildContext context,
    List<double> spending,
  ) {
    final maxSpending = spending.reduce((a, b) => a > b ? a : b);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.05),
            AppTheme.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '7-Day Spending',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Total: ${_formatCurrency(spending.fold(0.0, (a, b) => a + b))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = maxSpending > 0
                  ? (spending[index] / maxSpending * 60).clamp(4.0, 60.0)
                  : 4.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.accentColor,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                          .animate(delay: Duration(milliseconds: 100 * index))
                          .slideY(begin: 1, end: 0, duration: 400.ms)
                          .fadeIn(),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(
    BuildContext context,
    String category,
    double amount,
    double percentage,
  ) {
    final colors = [Colors.blue, Colors.green, Colors.orange];
    final colorIndex = category.hashCode.abs() % colors.length;
    final color = colors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child:
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate().slideX(
                      begin: -1,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% of total expenses',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
