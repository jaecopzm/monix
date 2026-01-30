import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/app_notification.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/notification_data_service.dart';
import '../services/custom_snackbar.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String initialType;
  final Transaction? transactionToEdit;

  const AddTransactionBottomSheet({
    super.key,
    this.initialType = 'expense',
    this.transactionToEdit,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DataService _dataService = DataService();
  final SettingsService _settings = SettingsService();

  String _selectedType = 'expense';
  String _selectedCategory = '';
  bool _showAllSubscriptions = false;
  DateTime _selectedDate = DateTime.now();
  List<Category> _categories = [];
  List<Goal> _goals = [];
  String? _selectedGoalId;
  String _currencySymbol = '\$';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _selectedType = widget.transactionToEdit!.type;
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = widget.transactionToEdit!.date;
      _amountController.text = widget.transactionToEdit!.amount.toString();
      _descriptionController.text = widget.transactionToEdit!.description ?? '';
    } else {
      _selectedType = widget.initialType;
    }
    _loadCategories();
    _loadGoals();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await _settings.getCurrency();
    setState(() {
      _currencySymbol =
          {
            'USD': '\$',
            'EUR': '€',
            'GBP': '£',
            'JPY': '¥',
            'ZMW': 'K',
          }[currency] ??
          '\$';
    });
  }

  Future<void> _loadGoals() async {
    final goals = await _dataService.getGoals();
    setState(() => _goals = goals.where((g) => g.progress < 1.0).toList());
  }

  Future<void> _loadCategories() async {
    final categories = await _dataService.getCategoriesByType(_selectedType);
    setState(() {
      _categories = categories;
      if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  Future<double> _getCurrentBalance() async {
    final transactions = await _dataService.getTransactions();
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    return income - expenses;
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final amount = double.parse(_amountController.text);

        // Check balance for expenses
        if (_selectedType == 'expense') {
          final balance = await _getCurrentBalance();
          if (amount > balance) {
            setState(() => _isLoading = false);
            if (!mounted) return;
            final proceed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Low Balance'),
                  ],
                ),
                content: Text(
                  'This expense of $_currencySymbol${amount.toStringAsFixed(2)} exceeds your current balance of $_currencySymbol${balance.toStringAsFixed(2)}.\n\nYour balance will be -$_currencySymbol${(amount - balance).toStringAsFixed(2)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Add Anyway'),
                  ),
                ],
              ),
            );
            if (proceed != true) return;
            setState(() => _isLoading = true);
          }
        }

      if (widget.transactionToEdit != null) {
        final updatedTransaction = widget.transactionToEdit!.copyWith(
          title: _selectedCategory,
          amount: amount,
          category: _selectedCategory,
          type: _selectedType,
          date: _selectedDate,
          description: _descriptionController.text,
        );
        await _dataService.updateTransaction(
          widget.transactionToEdit!,
          updatedTransaction,
        );
      } else {
        final transaction = Transaction(
          title: _selectedCategory,
          amount: amount,
          category: _selectedCategory,
          type: _selectedType,
          date: _selectedDate,
          description: _descriptionController.text,
        );
        await _dataService.insertTransaction(transaction);
        
        // Create in-app notification
        await _createTransactionNotification(transaction);
        
        // Send push notification
        await _sendPushNotification(transaction);
      }

      // Update goal if selected and type is income
      if (_selectedGoalId != null && _selectedType == 'income') {
        final goal = _goals.firstWhere((g) => g.id == _selectedGoalId);
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + amount,
        );
        await _dataService.updateGoal(updatedGoal);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            message: 'Error saving transaction: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _createTransactionNotification(Transaction transaction) async {
    final notificationService = NotificationDataService();
    final type = transaction.type == 'income' ? 'Income' : 'Expense';
    
    await notificationService.add(AppNotification(
      title: '$type Added',
      message: '${transaction.category}: $_currencySymbol${transaction.amount.toStringAsFixed(2)}',
      type: 'transaction_added',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _sendPushNotification(Transaction transaction) async {
    final notificationService = NotificationService();
    final type = transaction.type == 'income' ? 'Income' : 'Expense';
    
    await notificationService.showNotification(
      title: '$type Added',
      body: '${transaction.category}: $_currencySymbol${transaction.amount.toStringAsFixed(2)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transactionToEdit != null
                          ? 'Edit Transaction'
                          : 'Add Transaction',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildAmountField(),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    if (_selectedType == 'expense') ...[
                      const SizedBox(height: 16),
                      _buildSubscriptionSelector(),
                    ],
                    const SizedBox(height: 20),
                    _buildDateSelector(),
                    const SizedBox(height: 20),
                    if (_selectedType == 'income' && _goals.isNotEmpty) ...[
                      _buildGoalSelector(),
                      const SizedBox(height: 20),
                    ],
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton('Income', 'income', AppTheme.successColor),
          ),
          Expanded(
            child: _buildTypeButton('Expense', 'expense', AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = '';
        });
        _loadCategories();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        prefixIcon: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              _currencySymbol,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _selectedType == 'income'
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
          ),
        ),
        hintText: '0.00',
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        border: InputBorder.none,
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.fromLTRB(60, 20, 20, 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _selectedType == 'income'
                ? AppTheme.successColor
                : AppTheme.errorColor,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter amount';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category.name;
            final brandColor = CategoryIcons.getBrandColor(category.name);
            
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category.name),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected && brandColor != null
                      ? LinearGradient(
                          colors: [
                            brandColor.withValues(alpha: 0.15),
                            brandColor.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  color: isSelected && brandColor == null
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (brandColor ?? AppTheme.primaryColor)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcons.getIcon(
                      category.name,
                      type: _selectedType,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected
                            ? (brandColor ?? AppTheme.primaryColor)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Add a note (optional)',
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedType == 'income'
              ? AppTheme.successColor
              : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            : Text(
                widget.transactionToEdit != null
                    ? 'Update Transaction'
                    : 'Save Transaction',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildGoalSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contribute to Goal (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._goals.map((goal) {
              final isSelected = _selectedGoalId == goal.id;
              return GestureDetector(
                onTap: () => setState(
                  () => _selectedGoalId = isSelected ? null : goal.id,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.successColor : bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(goal.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        goal.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionSelector() {
    final subs = CategoryIcons.getCategoryNames(type: 'subscription');
    final displaySubs = _showAllSubscriptions ? subs : subs.take(8).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Services',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: displaySubs.map((name) {
            final selected = _selectedCategory == name;
            final brandColor = CategoryIcons.getBrandColor(name);
            
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = name);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: selected && brandColor != null
                      ? LinearGradient(
                          colors: [
                            brandColor.withValues(alpha: 0.15),
                            brandColor.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  color: selected && brandColor == null
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? (brandColor ?? AppTheme.primaryColor)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcons.getIcon(
                      name,
                      size: 20,
                      type: 'subscription',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                        color: selected
                            ? (brandColor ?? AppTheme.primaryColor)
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (subs.length > 8) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showAllSubscriptions = !_showAllSubscriptions);
              },
              icon: Icon(
                _showAllSubscriptions ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              label: Text(
                _showAllSubscriptions ? 'Show Less' : 'Show More',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
