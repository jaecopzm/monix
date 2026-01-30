import 'package:firebase_ai/firebase_ai.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'cache_service.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  Future<String> getFinancialInsights(
    List<Transaction> transactions,
    String currencySymbol, {
    bool useCache = true,
  }) async {
    if (transactions.isEmpty) {
      return "Add some transactions to get personalized financial insights!";
    }

    // Check cache first if enabled
    if (useCache) {
      final cachedInsights = await CacheService.getCachedAIInsights();
      if (cachedInsights != null) {
        return cachedInsights;
      }
    }

    // Prepare a summary of transactions for the AI
    final now = DateTime.now();
    final thisMonth = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final lastMonth = transactions
        .where(
          (t) =>
              t.date.year == (now.month == 1 ? now.year - 1 : now.year) &&
              t.date.month == (now.month == 1 ? 12 : now.month - 1),
        )
        .toList();

    final double thisMonthExpenses = thisMonth
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
    final double thisMonthIncome = thisMonth
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
    final double lastMonthExpenses = lastMonth
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);

    // Get category breakdown for this month
    final categories = <String, double>{};
    for (var t in thisMonth.where((t) => t.type == 'expense')) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : null;

    final prompt =
        '''
You are a professional financial advisor for Monixx, a premium finance app. 
Analyze the financial data and provide 3-4 insights in a clean, readable format.

IMPORTANT: Do NOT use markdown formatting like **bold** or *italic*. Instead, use plain text with proper capitalization and structure.

Use this EXACT format for each insight:
🎯 [INSIGHT TITLE IN CAPS]
[2-3 sentences explaining the insight with specific numbers and actionable advice]

DATA:
- Period: ${DateFormat('MMMM yyyy').format(now)}
- Income: $currencySymbol${thisMonthIncome.toStringAsFixed(2)}
- Expenses: $currencySymbol${thisMonthExpenses.toStringAsFixed(2)}
- Last Month: $currencySymbol${lastMonthExpenses.toStringAsFixed(2)}
${topCategory != null ? "- Top Category: ${topCategory.key} ($currencySymbol${topCategory.value.toStringAsFixed(2)})" : ""}

Requirements:
- Use emojis (💰 💡 📊 ⚠️ ✨ 🎯 📈 💪) to make it visually appealing
- Be specific with numbers and percentages
- Keep tone encouraging and professional
- Focus on actionable advice
- Compare trends when possible
- Use CAPS for emphasis instead of markdown bold
- No asterisks or markdown formatting
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final insights = response.text ??
          "I couldn't generate insights right now. Please try again later.";
      
      // Cache the insights
      await CacheService.cacheAIInsights(insights);
      
      return insights;
    } catch (e) {
      return "Error generating insights: $e";
    }
  }
}
