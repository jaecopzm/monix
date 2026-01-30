import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monixx/services/settings_service.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import '../services/data_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/category_icons.dart';
import '../models/category.dart';

class AddRecurringTransactionSheet extends StatefulWidget {
  final RecurringTransaction? recurring;

  const AddRecurringTransactionSheet({super.key, this.recurring});

  @override
  State<AddRecurringTransactionSheet> createState() =>
      _AddRecurringTransactionSheetState();
}

class _AddRecurringTransactionSheetState
    extends State<AddRecurringTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final RecurringTransactionService _service = RecurringTransactionService();
  final DataService _dataService = DataService();
  final SettingsService _settings = SettingsService();

  String _type = 'expense';
  String _category = 'Food';
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = false;
  bool _showAllSubscriptions = false;
  List<String> _categories = [];
  bool _isLoading = false;
  String _currencySymbol = '\$';

  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCurrency();
    if (widget.recurring != null) {
      _titleController.text = widget.recurring!.title;
      _amountController.text = widget.recurring!.amount.toString();
      _descriptionController.text = widget.recurring!.description ?? '';
      _type = widget.recurring!.type;
      _category = widget.recurring!.category;
      _frequency = widget.recurring!.frequency;
      _startDate = widget.recurring!.startDate;
      _endDate = widget.recurring!.endDate;
      _hasEndDate = _endDate != null;
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await _settings.getCurrency();
    setState(() {
      _currencySymbol = _currencySymbols[currency] ?? '\$';
    });
  }

  Future<void> _loadCategories() async {
    final cats = await _dataService.getCategories();
    setState(() {
      _categories = cats
          .where((c) => c.type == _type)
          .map((c) => c.name)
          .toList();
      if (_categories.isNotEmpty && !_categories.contains(_category)) {
        _category = _categories.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recurring == null
                          ? 'Add Recurring'
                          : 'Edit Recurring',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your subscriptions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    _buildTextField('Title', _titleController, 'e.g., Netflix'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Amount',
                      _amountController,
                      '0.00',
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    if (_type == 'expense') ...[
                      const Text(
                        'Select Service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPopularSubscriptions(),
                      const SizedBox(height: 16),
                    ],
                    _buildFrequencyDropdown(),
                    const SizedBox(height: 16),
                    _buildDatePicker('Start Date', _startDate, (date) {
                      setState(() => _startDate = date);
                    }),
                    const SizedBox(height: 16),
                    _buildEndDateToggle(),
                    if (_hasEndDate) ...[
                      const SizedBox(height: 16),
                      _buildDatePicker('End Date', _endDate ?? DateTime.now(), (
                        date,
                      ) {
                        setState(() => _endDate = date);
                      }),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Description',
                      _descriptionController,
                      'Optional',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildTypeButton('Expense', 'expense', Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeButton('Income', 'income', Colors.green)),
      ],
    );
  }

  Widget _buildTypeButton(String label, String value, Color color) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() {
          _type = value;
          _loadCategories();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value == 'income' ? Icons.trending_up : Icons.trending_down,
              color: isSelected ? color : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            prefixIcon: isNumber
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16),
                    child: Text(
                      _currencySymbol,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: maxLines == 1
              ? (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                }
              : null,
        ),
      ],
    );
  }


  Widget _buildPopularSubscriptions() {
    final subs = CategoryIcons.getCategoryNames(type: 'subscription');
    final displaySubs = _showAllSubscriptions ? subs : subs.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: displaySubs.map((name) {
            final selected = _category == name;
            return GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() {
                  _category = name;
                  _titleController.text = name;
                  final suggestedAmount = _getSuggestedAmount(name);
                  if (suggestedAmount != null) {
                    _amountController.text = suggestedAmount.toString();
                  }
                  if (!_categories.contains(name)) {
                    _categories.add(name);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  color: selected ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : Colors.grey.withValues(alpha: 0.15),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcons.getIcon(name, size: 22, type: 'subscription'),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                        color: selected
                            ? AppTheme.primaryColor
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
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticService.light();
                setState(() => _showAllSubscriptions = !_showAllSubscriptions);
              },
              icon: Icon(
                _showAllSubscriptions
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: AppTheme.primaryColor,
              ),
              label: Text(
                _showAllSubscriptions ? 'Show Less' : 'Show More',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _frequency,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            prefixIcon: const Icon(
              Icons.repeat,
              color: AppTheme.primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'daily',
              child: Text('Daily', style: TextStyle(fontSize: 15)),
            ),
            DropdownMenuItem(
              value: 'weekly',
              child: Text('Weekly', style: TextStyle(fontSize: 15)),
            ),
            DropdownMenuItem(
              value: 'monthly',
              child: Text('Monthly', style: TextStyle(fontSize: 15)),
            ),
            DropdownMenuItem(
              value: 'yearly',
              child: Text('Yearly', style: TextStyle(fontSize: 15)),
            ),
          ],
          onChanged: (value) => setState(() => _frequency = value!),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    void Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndDateToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.event_busy,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Set End Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          Switch(
            value: _hasEndDate,
            activeTrackColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _hasEndDate = value;
                if (!value) _endDate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.recurring == null ? Icons.add : Icons.check,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.recurring == null ? 'Add Recurring' : 'Update',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // If the selected category is not present locally, add it as an expense category
    if (!_categories.contains(_category)) {
      final iconPath =
          CategoryIcons.getIconPath(_category, type: 'subscription') ??
          CategoryIcons.getIconPath(_category, type: 'expense') ??
          '';
      final newCat = Category(
        name: _category,
        icon: iconPath,
        color: '#6C63FF',
        type: 'expense',
      );
      await _dataService.insertCategory(newCat);
      _categories.add(_category);
    }

    final recurring = RecurringTransaction(
      id: widget.recurring?.id,
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      category: _category,
      type: _type,
      frequency: _frequency,
      startDate: _startDate,
      endDate: _hasEndDate ? _endDate : null,
      lastProcessed: widget.recurring?.lastProcessed,
      isActive: widget.recurring?.isActive ?? true,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    try {
      if (widget.recurring == null) {
        await _service.add(recurring);
      } else {
        await _service.update(recurring);
      }
      if (mounted) {
        HapticService.medium();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _getSuggestedAmount(String service) {
    switch (service) {
      case 'Netflix':
        return 15.99;
      case 'Spotify':
        return 10.99;
      case 'YouTube':
        return 11.99;
      case 'Amazon Prime':
        return 14.99;
      case 'Apple':
        return 9.99;
      case 'Microsoft':
        return 6.99;
      case 'Adobe':
        return 54.99;
      case 'Hulu':
        return 7.99;
      case 'HBO':
        return 15.99;
      case 'Dropbox':
        return 11.99;
      case 'Google Drive':
        return 1.99;
      case 'iCloud':
        return 0.99;
      case 'GitHub':
        return 4.00;
      case 'LinkedIn':
        return 29.99;
      case 'Canva':
        return 12.99;
      case 'Figma':
        return 12.00;
      case 'Notion':
        return 8.00;
      case 'Slack':
        return 6.67;
      case 'Zoom':
        return 14.99;
      default:
        return null;
    }
  }
}
