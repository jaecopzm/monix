import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/goal.dart';
import '../../../services/data_service.dart';
import '../../../services/app_state_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/custom_snackbar.dart';
import '../../../services/smart_notification_service.dart';
import '../../../services/settings_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../theme/app_theme.dart';
import 'add_goal_bottom_sheet.dart';
import 'edit_goal_bottom_sheet.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final DataService _dataService = DataService();
  final AppStateService _appState = AppStateService();
  final SettingsService _settings = SettingsService();
  List<Goal> _goals = [];
  String _currencySymbol = '\$';
  String _selectedFilter = 'All';
  bool _isLoading = false;

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
    _loadGoals();
  }

  Future<void> _loadGoals({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final goals = await _appState.getGoals(forceRefresh: forceRefresh);
      final currency = await _settings.getCurrency();
      
      if (mounted) {
        setState(() {
          _goals = goals;
          _currencySymbol = _currencySymbols[currency] ?? '\$';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onGoalChanged() {
    _appState.invalidateGoals();
    _loadGoals(forceRefresh: true);
  }

  List<Goal> get _filteredGoals {
    switch (_selectedFilter) {
      case 'Active':
        return _goals.where((g) => g.progress < 1.0).toList();
      case 'Completed':
        return _goals.where((g) => g.progress >= 1.0).toList();
      case 'Short-term':
        return _goals.where((g) => g.deadline.difference(DateTime.now()).inDays <= 365).toList();
      case 'Long-term':
        return _goals.where((g) => g.deadline.difference(DateTime.now()).inDays > 365).toList();
      default:
        return _goals;
    }
  }

  void _showGoalOptions(Goal goal) {
    HapticService.medium();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              goal.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit Goal'),
              onTap: () {
                Navigator.pop(context);
                _showEditGoalSheet(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
              title: const Text('Add Funds'),
              onTap: () {
                Navigator.pop(context);
                _showAddFundsSheet(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('Duplicate Goal'),
              onTap: () {
                Navigator.pop(context);
                _duplicateGoal(goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Goal'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGoal(goal);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsSheet(Goal goal) {
    final amountController = TextEditingController();
    bool isLoading = false;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Funds to ${goal.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '$_currencySymbol ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : () async {
                    if (amountController.text.isNotEmpty) {
                      setModalState(() => isLoading = true);
                      try {
                        final oldProgress = goal.progress;
                        final newAmount = goal.currentAmount + double.parse(amountController.text);
                        final updatedGoal = goal.copyWith(currentAmount: newAmount);
                        await _dataService.updateGoal(updatedGoal);
                        
                        // Check for milestone achievements
                        try {
                          final smartNotifications = SmartNotificationService();
                          await smartNotifications.scheduleGoalMilestoneCheck(updatedGoal);
                        } catch (e) {
                          // Silent fail for notifications
                          print('Milestone notification failed: $e');
                        }
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          _onGoalChanged();
                        }
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            message: 'Error adding funds: $e',
                            type: SnackBarType.error,
                          );
                        }
                      }
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Funds'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _duplicateGoal(Goal goal) async {
    final newGoal = Goal(
      title: '${goal.title} (Copy)',
      targetAmount: goal.targetAmount,
      deadline: DateTime.now().add(const Duration(days: 365)),
      icon: goal.icon,
    );
    
    await _dataService.insertGoal(newGoal);
    _onGoalChanged();
    
    if (mounted) {
      CustomSnackBar.show(
        context,
        message: 'Goal duplicated successfully',
        type: SnackBarType.success,
      );
    }
  }

  void _confirmDeleteGoal(Goal goal) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dataService.deleteGoal(goal.id!);
              _onGoalChanged();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditGoalSheet(Goal goal) {
    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditGoalBottomSheet(
        goal: goal,
        currencySymbol: _currencySymbol,
        onGoalUpdated: _onGoalChanged,
      ),
    );
  }

  void _showAddGoalSheet() {
    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGoalBottomSheet(
        currencySymbol: _currencySymbol,
        onGoalCreated: _onGoalChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGoals = _filteredGoals;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with stats
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goals',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _showAddGoalSheet,
                        icon: const Icon(Icons.add_circle),
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  if (_goals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            
            // Goals list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadGoals(forceRefresh: true),
                child: filteredGoals.isEmpty
                    ? _goals.isEmpty
                        ? EmptyState(
                            svgPath: 'assets/svgs/no-goals.svg',
                            title: 'No Goals Yet',
                            message: 'Set financial goals to track your progress and stay motivated',
                            actionText: 'Create Goal',
                            onAction: _showAddGoalSheet,
                          )
                        : _buildEmptyFilter()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredGoals.length,
                        itemBuilder: (context, index) {
                          final goal = filteredGoals[index];
                          return Dismissible(
                            key: Key(goal.id!),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              await _dataService.deleteGoal(goal.id!);
                              _onGoalChanged();
                            },
                            child: GestureDetector(
                              onTap: () => _showEditGoalSheet(goal),
                              onLongPress: () => _showGoalOptions(goal),
                              child: _buildGoalCard(goal, index),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalGoals = _goals.length;
    final completedGoals = _goals.where((g) => g.progress >= 1.0).length;
    final totalTarget = _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', totalGoals.toString(), Icons.flag)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Done', completedGoals.toString(), Icons.check_circle)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Progress', '${totalTarget > 0 ? ((totalSaved / totalTarget) * 100).toInt() : 0}%', Icons.trending_up)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Active', 'Completed', 'Short-term', 'Long-term'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.transparent,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No goals match this filter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _selectedFilter = 'All'),
            child: const Text('Show All Goals'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, int index) {
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final isCompleted = goal.progress >= 1.0;
    final isOverdue = daysLeft < 0 && !isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [AppTheme.successColor.withValues(alpha: 0.1), AppTheme.successColor.withValues(alpha: 0.05)]
              : isOverdue
                  ? [AppTheme.errorColor.withValues(alpha: 0.1), AppTheme.errorColor.withValues(alpha: 0.05)]
                  : [AppTheme.primaryColor.withValues(alpha: 0.05), AppTheme.secondaryColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.cardShadow],
        border: Border.all(
          color: isCompleted
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : isOverdue
                  ? AppTheme.errorColor.withValues(alpha: 0.3)
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            if (isCompleted || isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.successColor : AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted ? 'Completed!' : 'Overdue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (isCompleted || isOverdue) const SizedBox(height: 12),
            
            // Goal header
            Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isOverdue ? '${daysLeft.abs()} days overdue' : '$daysLeft days left',
                        style: TextStyle(
                          color: isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_currencySymbol${goal.currentAmount.toStringAsFixed(0)} / $_currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  isCompleted ? AppTheme.successColor : AppTheme.primaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '${(goal.progress * 100).toStringAsFixed(0)}% completed',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
  }
}
