import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/goal.dart';
import '../../services/data_service.dart';
import '../../services/custom_snackbar.dart';
import '../../services/smart_notification_service.dart';
import '../../theme/app_theme.dart';

class AddGoalBottomSheet extends StatefulWidget {
  final String currencySymbol;
  final VoidCallback onGoalCreated;
  final Map<String, dynamic>? template;

  const AddGoalBottomSheet({
    super.key,
    required this.currencySymbol,
    required this.onGoalCreated,
    this.template,
  });

  @override
  State<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends State<AddGoalBottomSheet> {
  final DataService _dataService = DataService();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedIcon;
  bool _showTemplates = false;
  bool _isLoading = false;

  final List<String> _icons = [
    '🎯', '🏠', '🚗', '✈️', '💻', '📱', '🎓', '💍', '🏖️', '💰', '🛡️', '🎮'
  ];

  final List<Map<String, dynamic>> _goalTemplates = [
    {'title': 'Emergency Fund', 'icon': '🛡️', 'amount': 5000.0, 'days': 365},
    {'title': 'New Car', 'icon': '🚗', 'amount': 25000.0, 'days': 730},
    {'title': 'Vacation', 'icon': '✈️', 'amount': 3000.0, 'days': 180},
    {'title': 'New Phone', 'icon': '📱', 'amount': 1000.0, 'days': 90},
    {'title': 'House Down Payment', 'icon': '🏠', 'amount': 50000.0, 'days': 1095},
    {'title': 'Education', 'icon': '🎓', 'amount': 10000.0, 'days': 365},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.template?['title']?.toString() ?? '',
    );
    _amountController = TextEditingController(
      text: widget.template != null 
          ? (widget.template!['amount'] as num).toStringAsFixed(0) 
          : '',
    );
    _selectedDate = widget.template != null 
        ? DateTime.now().add(Duration(days: widget.template!['days'] as int))
        : DateTime.now().add(const Duration(days: 30));
    _selectedIcon = widget.template?['icon']?.toString() ?? '🎯';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'].toString();
      _amountController.text = (template['amount'] as num).toStringAsFixed(0);
      _selectedDate = DateTime.now().add(Duration(days: template['days'] as int));
      _selectedIcon = template['icon'].toString();
      _showTemplates = false;
    });
  }

  Future<void> _createGoal() async {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        HapticFeedback.lightImpact();
        
        final goal = Goal(
          title: _titleController.text,
          targetAmount: double.parse(_amountController.text),
          deadline: _selectedDate,
          icon: _selectedIcon,
        );
        
        await _dataService.insertGoal(goal);
        
        // Schedule goal notifications after goal is created with ID
        try {
          final smartNotifications = SmartNotificationService();
          await smartNotifications.scheduleGoalDeadlineReminder(goal);
        } catch (e) {
          // Silent fail for notifications - don't block goal creation
          print('Notification scheduling failed: $e');
        }
        
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);
          widget.onGoalCreated();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            message: 'Error creating goal: $e',
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
            Row(
              children: [
                Text(
                  widget.template != null ? 'Create from Template' : 'New Goal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (!_showTemplates)
                  TextButton.icon(
                    onPressed: () => setState(() => _showTemplates = true),
                    icon: const Icon(Icons.library_books, size: 18),
                    label: const Text('Templates'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_showTemplates) ...[
              _buildTemplateSection(),
            ] else ...[
              _buildGoalForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Choose Template', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _showTemplates = false),
              child: const Text('Custom'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_goalTemplates.length, (index) {
          final template = _goalTemplates[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(template['icon'].toString(), style: const TextStyle(fontSize: 20)),
              ),
              title: Text(template['title'].toString()),
              subtitle: Text(
                '${widget.currencySymbol}${(template['amount'] as num).toStringAsFixed(0)} • ${template['days']} days',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _applyTemplate(template),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGoalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            hintText: 'e.g., New Car',
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
        
        // Create button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _createGoal,
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
                : const Text('Create Goal'),
          ),
        ),
      ],
    );
  }
}
