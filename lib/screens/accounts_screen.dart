import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/account.dart';
import '../services/database_helper.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    _accounts = await _db.getAccounts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _accounts.fold(0.0, (sum, acc) => sum + acc.balance);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticService.light();
              _showAddAccountSheet();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTotalBalanceCard(totalBalance),
                Expanded(
                  child: _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No accounts yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            return _buildAccountCard(_accounts[index], index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalBalanceCard(double total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_accounts.length} ${_accounts.length == 1 ? 'account' : 'accounts'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildAccountCard(Account account, int index) {
    final color = Color(int.parse('FF${account.color}', radix: 16));

    return GestureDetector(
      onTap: () => _showEditAccountSheet(account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: account.isDefault ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: account.isDefault ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(account.icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (account.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getAccountTypeName(account.type),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${account.balance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: account.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteAccount(account),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.2, end: 0),
    );
  }

  String _getAccountTypeName(String type) {
    switch (type) {
      case 'cash': return 'Cash';
      case 'bank': return 'Bank Account';
      case 'credit_card': return 'Credit Card';
      case 'savings': return 'Savings';
      case 'investment': return 'Investment';
      default: return type;
    }
  }

  void _showAddAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAccountSheet(onSave: _loadAccounts),
    );
  }

  void _showEditAccountSheet(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAccountSheet(account: account, onSave: _loadAccounts),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    if (account.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default account')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticService.heavy();
      await _db.deleteAccount(account.id!);
      _loadAccounts();
    }
  }
}

class _AddAccountSheet extends StatefulWidget {
  final Account? account;
  final VoidCallback onSave;

  const _AddAccountSheet({this.account, required this.onSave});

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper();

  String _type = 'cash';
  String _icon = '💵';
  bool _isDefault = false;
  bool _isLoading = false;

  final Map<String, String> _typeIcons = {
    'cash': '💵',
    'bank': '🏦',
    'credit_card': '💳',
    'savings': '🏦',
    'investment': '📈',
  };

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _type = widget.account!.type;
      _icon = widget.account!.icon;
      _isDefault = widget.account!.isDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.account == null ? 'Add Account' : 'Edit Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Account Name'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _balanceController,
                      decoration: const InputDecoration(labelText: 'Initial Balance'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Account Type'),
                      items: _typeIcons.keys.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Text(_typeIcons[type]!, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(_getTypeName(type)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                          _icon = _typeIcons[value]!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Set as default account'),
                      value: _isDefault,
                      onChanged: (value) => setState(() => _isDefault = value),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.account == null ? 'Add' : 'Update', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'cash': return 'Cash';
      case 'bank': return 'Bank Account';
      case 'credit_card': return 'Credit Card';
      case 'savings': return 'Savings';
      case 'investment': return 'Investment';
      default: return type;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final account = Account(
      id: widget.account?.id,
      name: _nameController.text,
      type: _type,
      balance: double.parse(_balanceController.text),
      icon: _icon,
      color: '6C63FF',
      isDefault: _isDefault,
    );

    try {
      if (widget.account == null) {
        await _db.insertAccount(account);
      } else {
        await _db.updateAccount(account);
      }
      
      if (mounted) {
        HapticService.medium();
        Navigator.pop(context);
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}
