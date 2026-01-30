import 'package:flutter/material.dart';
import '../utils/category_icons.dart';

class SubscriptionCard extends StatelessWidget {
  final String serviceName;
  final double amount;
  final String frequency;
  final DateTime nextPayment;

  const SubscriptionCard({
    super.key,
    required this.serviceName,
    required this.amount,
    required this.frequency,
    required this.nextPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: CategoryIcons.getIcon(
            serviceName,
            type: 'subscription',
            size: 24,
          ),
        ),
        title: Text(serviceName),
        subtitle: Text('$frequency • Next: ${_formatDate(nextPayment)}'),
        trailing: Text(
          '-\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

// Example usage in recurring transactions
class RecurringTransactionsList extends StatelessWidget {
  const RecurringTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptions = [
      {'name': 'Netflix', 'amount': 15.99, 'frequency': 'Monthly'},
      {'name': 'Spotify', 'amount': 9.99, 'frequency': 'Monthly'},
      {'name': 'Adobe', 'amount': 52.99, 'frequency': 'Monthly'},
      {'name': 'GitHub', 'amount': 4.00, 'frequency': 'Monthly'},
      {'name': 'Gym', 'amount': 29.99, 'frequency': 'Monthly'},
    ];

    return Column(
      children: [
        const Text('Subscription Services', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...subscriptions.map((sub) => SubscriptionCard(
          serviceName: sub['name'] as String,
          amount: sub['amount'] as double,
          frequency: sub['frequency'] as String,
          nextPayment: DateTime.now().add(const Duration(days: 15)),
        )),
      ],
    );
  }
}
