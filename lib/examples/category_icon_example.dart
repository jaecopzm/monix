import 'package:flutter/material.dart';
import '../utils/category_icons.dart';

class CategoryIconExample extends StatelessWidget {
  const CategoryIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Icons')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Categories:', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: CategoryIcons.getCategoryNames(type: 'expense')
                  .map((category) => _buildCategoryChip(category, 'expense'))
                  .toList(),
            ),
            const SizedBox(height: 32),
            const Text('Income Categories:', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: CategoryIcons.getCategoryNames(type: 'income')
                  .map((category) => _buildCategoryChip(category, 'income'))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String type) {
    return Chip(
      avatar: CategoryIcons.getIcon(
        category,
        type: type,
        size: 20,
        color: type == 'expense' ? Colors.red : Colors.green,
      ),
      label: Text(category),
    );
  }
}

// Example usage in your existing transaction item widget:
class TransactionItemWithIcon extends StatelessWidget {
  final String category;
  final String type;
  final double amount;

  const TransactionItemWithIcon({
    super.key,
    required this.category,
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: type == 'expense' 
          ? Colors.red.withOpacity(0.1) 
          : Colors.green.withOpacity(0.1),
        child: CategoryIcons.getIcon(
          category,
          type: type,
          size: 24,
          color: type == 'expense' ? Colors.red : Colors.green,
        ),
      ),
      title: Text(category),
      trailing: Text(
        '${type == 'expense' ? '-' : '+'}${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: type == 'expense' ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
