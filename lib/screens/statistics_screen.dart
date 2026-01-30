import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/settings_service.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../services/haptic_service.dart';
import '../services/cache_service.dart';
import '../widgets/rich_insight_text.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DataService _dataService = DataService();
  List<Transaction> _transactions = [];
  final Map<String, double> _categoryExpenses = {};
  final Map<String, double> _monthlyData = {};
  String _currencySymbol = '\$';
  final SettingsService _settings = SettingsService();
  final AIService _aiService = AIService();
  final PdfService _pdfService = PdfService();

  String? _aiInsights;
  bool _isAILoading = false;
  bool _aiInsightsLoaded = false;
  String? _aiError;
  String _selectedPeriod = 'monthly'; // monthly, yearly, advanced
  bool _isExporting = false;
  final bool _isPremium = true; // For future gating

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
  }

  Future<void> _loadData() async {
    final transactions = await _dataService.getTransactions();
    final currency = await _settings.getCurrency();

    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _currencySymbol = _currencySymbols[currency] ?? '\$';
      _calculateCategoryExpenses();
      _calculateMonthlyData();
    });
    
    // Load cached AI insights if available
    if (_isPremium && transactions.isNotEmpty) {
      _loadCachedAIInsights();
    }
  }

  Future<void> _loadCachedAIInsights() async {
    final cachedInsights = await CacheService.getCachedAIInsights();
    if (cachedInsights != null && mounted) {
      setState(() {
        _aiInsights = cachedInsights;
        _aiInsightsLoaded = true;
      });
    }
  }

  Future<void> _loadAIInsights({bool forceRefresh = false}) async {
    if (_transactions.isEmpty) return;
    setState(() {
      _isAILoading = true;
      _aiError = null;
    });
    try {
      final insights = await _aiService.getFinancialInsights(
        _transactions,
        _currencySymbol,
        useCache: !forceRefresh,
      );
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isAILoading = false;
          _aiInsightsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAILoading = false;
          _aiError = 'Failed to generate insights. Please try again.';
        });
      }
    }
  }

  void _calculateCategoryExpenses() {
    _categoryExpenses.clear();
    final periodTransactions = _getTransactionsForPeriod();
    for (var transaction in periodTransactions) {
      if (transaction.type == 'expense') {
        _categoryExpenses[transaction.category] =
            (_categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }
  }

  void _calculateMonthlyData() {
    _monthlyData.clear();
    final periodTransactions = _getTransactionsForPeriod();
    for (var transaction in periodTransactions) {
      final monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      if (transaction.type == 'expense') {
        _monthlyData[monthKey] =
            (_monthlyData[monthKey] ?? 0) + transaction.amount;
      }
    }
  }

  List<Transaction> _getTransactionsForPeriod() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'advanced':
        startDate = DateTime(now.year, now.month - 6, 1);
        break;
      case 'monthly':
      default:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    return _transactions
        .where(
          (t) => t.date.isAfter(startDate.subtract(const Duration(seconds: 1))),
        )
        .toList();
  }

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);
    HapticService.medium();

    try {
      await _pdfService.generateAnalyticsReport(
        transactions: _transactions,
        currencySymbol: _currencySymbol,
        period: _selectedPeriod == 'monthly' ? 'month' : 'year',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
        title: const Text('Statistics'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFFF5F5F5),
        elevation: 0,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _exportPDF,
              tooltip: 'Export PDF Report',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              _buildOverviewCards(),
              const SizedBox(height: 24),
              if (_isPremium) ...[
                _buildFinancialHealthScore(),
                const SizedBox(height: 24),
                _buildComparativeAnalysis(),
                const SizedBox(height: 24),
                _buildPredictiveAnalytics(),
                const SizedBox(height: 24),
              ],
              _buildMonthlyComparison(),
              const SizedBox(height: 24),
              _buildAIInsights(),
              const SizedBox(height: 24),
              _buildCategoryBreakdown(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalIncome = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpenses) / totalIncome * 100)
              .clamp(0.0, 100.0)
              .toDouble()
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Income',
                totalIncome,
                AppTheme.successColor,
                Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Expenses',
                totalExpenses,
                AppTheme.errorColor,
                Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSavingsCard(savingsRate, totalIncome - totalExpenses),
      ],
    );
  }

  Widget _buildSavingsCard(double rate, double amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.secondaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings Rate',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${amount >= 0 ? '+' : ''}$_currencySymbol${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '$_currencySymbol${amount.toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryExpenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No expenses yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final sortedCategories = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _categoryExpenses.values.fold(0.0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Categories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...sortedCategories
              .take(5)
              .map((e) => _buildCategoryItem(e.key, e.value, total)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCategoryItem(String category, double amount, double total) {
    final percentage = (amount / total * 100);
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];
    final color = colors[category.hashCode.abs() % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_currencySymbol${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparison() {
    final now = DateTime.now();
    final monthlyExpenses = <String, double>{};

    // Calculate last 6 months or 12 based on period
    final int monthsCount = _selectedPeriod == 'advanced' ? 12 : 6;
    for (var i = monthsCount - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyExpenses[key] = 0;
    }

    // Fill with actual data
    for (var t in _transactions.where((t) => t.type == 'expense')) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      if (monthlyExpenses.containsKey(key)) {
        monthlyExpenses[key] = monthlyExpenses[key]! + t.amount;
      }
    }

    final values = monthlyExpenses.values.toList();
    final maxY = values.isEmpty || values.every((v) => v == 0)
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b) * 1.2;

    final monthLabels = monthlyExpenses.keys.map((k) {
      final parts = k.split('-');
      return DateFormat(
        'MMM',
      ).format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPeriod == 'monthly' ? 'Recent Spending' : 'Spending Trend',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '$_currencySymbol${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthLabels[idx],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: values.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: _selectedPeriod == 'advanced' ? 12 : 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          _buildPeriodChip('Monthly', 'monthly'),
          _buildPeriodChip('Yearly', 'yearly'),
          _buildPeriodChip('Advanced', 'advanced'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() {
            _selectedPeriod = period;
            _calculateCategoryExpenses();
            _calculateMonthlyData();
          });
          if (period == 'advanced' && !_aiInsightsLoaded) {
            _loadAIInsights();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    if (!_isPremium) {
      return _buildPremiumLock(
        title: 'AI Financial Insights',
        description: 'Get personalized AI-powered insights about your spending habits, trends, and recommendations',
        icon: Icons.auto_awesome,
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Financial Insights',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (!_isAILoading)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _transactions.isEmpty ? null : () {
                        HapticService.light();
                        _loadAIInsights(forceRefresh: true);
                      },
                      icon: const Icon(Icons.psychology, size: 18),
                      label: Text(_aiInsights == null ? 'Generate' : 'Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    if (_aiInsights != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          await CacheService.clearAIInsightsCache();
                          setState(() {
                            _aiInsights = null;
                            _aiInsightsLoaded = false;
                          });
                          HapticService.light();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache cleared'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.clear_all, size: 20),
                        tooltip: 'Clear cache',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isAILoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Generating AI insights...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (_aiError != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _aiError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _loadAIInsights(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            )
          else if (_aiInsights != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichInsightText(text: _aiInsights!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    FutureBuilder<bool>(
                      future: CacheService.hasValidCache(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return const Text(
                            'Cached • Updates daily',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        }
                        return const Text(
                          'Fresh insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 48,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ready to analyze your finances!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click "Generate" to get personalized AI insights about your spending patterns and financial health.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildFinancialHealthScore() {
    final totalIncome = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final savingsRate = totalIncome > 0 
        ? ((totalIncome - totalExpenses) / totalIncome * 100).clamp(0, 100)
        : 0.0;
    const budgetAdherence = 85.0; // Placeholder
    const spendingConsistency = 78.0; // Placeholder
    
    final healthScore = ((savingsRate + budgetAdherence + spendingConsistency) / 3).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.accentColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Financial Health Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    healthScore > 70 ? Colors.green : 
                    healthScore > 40 ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$healthScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    healthScore > 70 ? 'Excellent' : 
                    healthScore > 40 ? 'Good' : 'Needs Work',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHealthMetric('Savings Rate', savingsRate.toDouble()),
          const SizedBox(height: 12),
          _buildHealthMetric('Budget Adherence', budgetAdherence.toDouble()),
          const SizedBox(height: 12),
          _buildHealthMetric('Spending Consistency', spendingConsistency),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildHealthMetric(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              value > 70 ? Colors.green : 
              value > 40 ? Colors.orange : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparativeAnalysis() {
    final now = DateTime.now();
    final thisMonth = _transactions.where((t) => 
      t.date.year == now.year && t.date.month == now.month && t.type == 'expense'
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final lastMonth = _transactions.where((t) => 
      t.date.year == (now.month == 1 ? now.year - 1 : now.year) && 
      t.date.month == (now.month == 1 ? 12 : now.month - 1) && 
      t.type == 'expense'
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final change = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth * 100) : 0.0;
    final isIncrease = change > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Month Comparison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  'Last Month',
                  lastMonth,
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonCard(
                  'This Month',
                  thisMonth,
                  isIncrease ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isIncrease ? Colors.red : Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  color: isIncrease ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '${change.abs().toStringAsFixed(1)}% ${isIncrease ? "increase" : "decrease"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncrease ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildComparisonCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_currencySymbol${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveAnalytics() {
    final now = DateTime.now();
    final last3Months = _transactions.where((t) => 
      t.date.isAfter(DateTime(now.year, now.month - 3, now.day)) && 
      t.type == 'expense'
    ).fold(0.0, (sum, t) => sum + t.amount);
    
    final avgMonthly = last3Months / 3;
    final predicted = avgMonthly * 1.05; // 5% buffer
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Next Month Forecast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Predicted Spending',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currencySymbol${predicted.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Based on 3-month average',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.purple,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Set aside ${(predicted * 0.1).toStringAsFixed(0)} for unexpected expenses',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildPremiumLock({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 2,
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
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to premium subscription page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium features coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.star_rounded),
            label: const Text('Upgrade to Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureBadge('Advanced Analytics'),
              const SizedBox(width: 8),
              _buildFeatureBadge('AI Insights'),
              const SizedBox(width: 8),
              _buildFeatureBadge('Export PDF'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildFeatureBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.amber,
        ),
      ),
    );
  }
}
