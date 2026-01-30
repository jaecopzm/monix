import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/goal.dart';
import '../../services/data_service.dart';
import '../../services/custom_snackbar.dart';
import '../../theme/app_theme.dart';

class EditGoalBottomSheet extends StatefulWidget {
  final Goal goal;
  final String currencySymbol;
  final VoidCallback onGoalUpdated;

  const EditGoalBottomSheet({
    super.key,
    required this.goal,
    required this.currencySymbol,
    required this.onGoalUpdated,
  });

  @override
  State<EditGoalBottomSheet> createState() => _EditGoalBottomSheetState();
}

class _EditGoalBottomSheetState extends State<EditGoalBottomSheet> {
  final DataService _dataService = DataService();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _currentAmountController;
  late DateTime _selectedDate;
  late String _selectedIcon;
  bool _isLoading = false;

  final List<String> _icons = [
    '🎯', '🏠', '🚗', '✈️', '💻', '📱', '🎓', '💍', '🏖️', '💰', '🛡️', '🎮'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _amountController = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(0));
    _currentAmountController = TextEditingController(text: widget.goal.currentAmount.toStringAsFixed(0));
    _selectedDate = widget.goal.deadline;
    _selectedIcon = widget.goal.icon;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _updateGoal() async {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        HapticFeedback.lightImpact();
        
        final updatedGoal = widget.goal.copyWith(
          title: _titleController.text,
          targetAmount: double.parse(_amountController.text),
          currentAmount: double.parse(_currentAmountController.text),
          deadline: _selectedDate,
          icon: _selectedIcon,
        );
        
        await _dataService.updateGoal(updatedGoal);
        
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          widget.onGoalUpdated();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            message: 'Error updating goal: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Header
            Text(
              'Edit Goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 20),
            
            // Icon selection
            const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) => GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIcon == icon
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedIcon == icon
                          ? AppTheme.primaryColor
                          : Colors.grey.withValues(alpha: 0.3),
                      width: _selectedIcon == icon ? 2 : 1,
                    ),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Goal title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Target amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixText: '${widget.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current amount
            TextField(
              controller: _currentAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Amount',
                prefixText: '${widget.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Deadline
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    const Spacer(),
                    Text(
                      '${_selectedDate.difference(DateTime.now()).inDays} days',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Update button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _updateGoal,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
