import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateAnalyticsReport({
    required List<Transaction> transactions,
    required String currencySymbol,
    required String period,
  }) async {
    final pdf = pw.Document();

    // Calculate data
    final now = DateTime.now();
    final monthlyData = _getMonthlyData(transactions, period);
    final categoryData = _getCategoryBreakdown(transactions, period);
    final comparison = _getMonthComparison(transactions);

    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Financial Analytics Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on ${DateFormat('MMM dd, yyyy').format(now)}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                'Total Income',
                totalIncome,
                currencySymbol,
                PdfColors.green,
              ),
              pw.SizedBox(width: 16),
              _buildSummaryCard(
                'Total Expenses',
                totalExpenses,
                currencySymbol,
                PdfColors.red,
              ),
              pw.SizedBox(width: 16),
              _buildSummaryCard(
                'Net Balance',
                totalIncome - totalExpenses,
                currencySymbol,
                PdfColors.blue,
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Month Comparison
          pw.Text(
            'Monthly Comparison',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'This Month: $currencySymbol${comparison['current'].toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Last Month: $currencySymbol${comparison['previous'].toStringAsFixed(2)}',
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  (comparison['isIncrease'] as bool)
                      ? '↑ Increased by ${(comparison['change'] as double).toStringAsFixed(1)}%'
                      : '↓ Decreased by ${(comparison['change'] as double).toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    color: (comparison['isIncrease'] as bool)
                        ? PdfColors.red
                        : PdfColors.green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Category Breakdown
          pw.Text(
            'Category Breakdown',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...categoryData.map((cat) => _buildCategoryRow(cat, currencySymbol)),

          pw.SizedBox(height: 30),

          // Monthly Trend Table
          pw.Text(
            'Monthly Spending Trend',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Month', isHeader: true),
                  _buildTableCell('Amount', isHeader: true),
                ],
              ),
              ...monthlyData.map(
                (data) => pw.TableRow(
                  children: [
                    _buildTableCell(data['month'] as String),
                    _buildTableCell(
                      '$currencySymbol${(data['amount'] as double).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Text(
            'Report generated by Monixx - Your Financial Companion',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildSummaryCard(
    String title,
    double amount,
    String currency,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '$currency${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCategoryRow(Map<String, dynamic> cat, String currency) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            cat['name'] as String,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '$currency${(cat['amount'] as double).toStringAsFixed(2)} (${(cat['percentage'] as double).toStringAsFixed(1)}%)',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthlyData(
    List<Transaction> transactions,
    String period,
  ) {
    final months = period == '3months'
        ? 3
        : period == '6months'
        ? 6
        : 12;
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTransactions = transactions.where(
        (t) =>
            t.type == 'expense' &&
            t.date.year == month.year &&
            t.date.month == month.month,
      );
      final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);

      data.add({
        'month': DateFormat('MMM yyyy').format(month),
        'amount': total,
      });
    }
    return data;
  }

  List<Transaction> _getTransactionsForPeriod(
    List<Transaction> transactions,
    String period,
  ) {
    final months = period == '3months'
        ? 3
        : period == '6months'
        ? 6
        : 12;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    return transactions
        .where(
          (t) => t.date.isAfter(startDate.subtract(const Duration(seconds: 1))),
        )
        .toList();
  }

  List<Map<String, dynamic>> _getCategoryBreakdown(
    List<Transaction> transactions,
    String period,
  ) {
    final periodTransactions = _getTransactionsForPeriod(transactions, period);
    final periodExpenses = periodTransactions.where((t) => t.type == 'expense');

    final categoryTotals = <String, double>{};
    for (var t in periodExpenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);

    return categoryTotals.entries
        .map(
          (e) => {
            'name': e.key,
            'amount': e.value,
            'percentage': total > 0 ? (e.value / total * 100).toDouble() : 0.0,
          },
        )
        .toList()
      ..sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );
  }

  Map<String, dynamic> _getMonthComparison(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonth = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final lastMonth = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.year == (now.month == 1 ? now.year - 1 : now.year) &&
              t.date.month == (now.month == 1 ? 12 : now.month - 1),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final change = lastMonth > 0
        ? ((thisMonth - lastMonth) / lastMonth * 100)
        : 0.0;

    return {
      'current': thisMonth,
      'previous': lastMonth,
      'change': change.abs(),
      'isIncrease': change > 0,
    };
  }
}
