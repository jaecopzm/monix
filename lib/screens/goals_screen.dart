// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:intl/intl.dart';
// import '../models/goal.dart';
// import '../services/data_service.dart';
// import '../services/haptic_service.dart';
// import '../widgets/empty_state.dart';
// import '../theme/app_theme.dart';
// import '../services/settings_service.dart';

// class GoalsScreen extends StatefulWidget {
//   const GoalsScreen({super.key});

//   @override
//   State<GoalsScreen> createState() => _GoalsScreenState();
// }

// class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
//   final DataService _dataService = DataService();
//   List<Goal> _goals = [];
//   final SettingsService _settings = SettingsService();
//   String _currencySymbol = '\$';
//   String _selectedFilter = 'All';
//   late AnimationController _fabController;

//   final Map<String, String> _currencySymbols = {
//     'USD': '\$',
//     'EUR': '€',
//     'GBP': '£',
//     'JPY': '¥',
//     'ZMW': 'K',
//   };

//   final List<Map<String, dynamic>> _goalTemplates = [
//     {'title': 'Emergency Fund', 'icon': '🛡️', 'amount': 5000.0, 'days': 365},
//     {'title': 'New Car', 'icon': '🚗', 'amount': 25000.0, 'days': 730},
//     {'title': 'Vacation', 'icon': '✈️', 'amount': 3000.0, 'days': 180},
//     {'title': 'New Phone', 'icon': '📱', 'amount': 1000.0, 'days': 90},
//     {'title': 'House Down Payment', 'icon': '🏠', 'amount': 50000.0, 'days': 1095},
//     {'title': 'Education', 'icon': '🎓', 'amount': 10000.0, 'days': 365},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fabController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _loadGoals();
//   }

//   @override
//   void dispose() {
//     _fabController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadGoals() async {
//     final goals = await _dataService.getGoals();
//     final currency = await _settings.getCurrency();
//     setState(() {
//       _goals = goals;
//       _currencySymbol = _currencySymbols[currency] ?? '\$';
//     });
//   }

//   List<Goal> get _filteredGoals {
//     switch (_selectedFilter) {
//       case 'Active':
//         return _goals.where((g) => g.progress < 1.0).toList();
//       case 'Completed':
//         return _goals.where((g) => g.progress >= 1.0).toList();
//       case 'Short-term':
//         return _goals.where((g) => g.deadline.difference(DateTime.now()).inDays <= 365).toList();
//       case 'Long-term':
//         return _goals.where((g) => g.deadline.difference(DateTime.now()).inDays > 365).toList();
//       default:
//         return _goals;
//     }
//   }

//   void _showGoalOptions() {
//     HapticService.light();
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text('Create Goal', style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildOptionCard(
//                     'Custom Goal',
//                     '🎯',
//                     'Create your own goal',
//                     () {
//                       Navigator.pop(context);
//                       _showAddGoalSheet();
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildOptionCard(
//                     'From Template',
//                     '📋',
//                     'Use a preset goal',
//                     () {
//                       Navigator.pop(context);
//                       _showTemplateSheet();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOptionCard(String title, String icon, String subtitle, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: AppTheme.primaryColor.withValues(alpha: 0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
//         ),
//         child: Column(
//           children: [
//             Text(icon, style: const TextStyle(fontSize: 32)),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: AppTheme.textSecondary,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showTemplateSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text('Goal Templates', style: Theme.of(context).textTheme.titleLarge),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 itemCount: _goalTemplates.length,
//                 itemBuilder: (context, index) {
//                   final template = _goalTemplates[index];
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: ListTile(
//                       leading: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryColor.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(template['icon'], style: const TextStyle(fontSize: 20)),
//                       ),
//                       title: Text(template['title']),
//                       subtitle: Text('$_currencySymbol${template['amount'].toStringAsFixed(0)} • ${template['days']} days'),
//                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                       onTap: () {
//                         Navigator.pop(context);
//                         _showAddGoalSheet(template: template);
//                       },
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAddGoalSheet({Map<String, dynamic>? template}) {
//     HapticFeedback.lightImpact();
//     final titleController = TextEditingController(text: template?['title'] ?? '');
//     final amountController = TextEditingController(
//       text: template != null ? template['amount'].toStringAsFixed(0) : '',
//     );
//     DateTime selectedDate = template != null 
//         ? DateTime.now().add(Duration(days: template['days']))
//         : DateTime.now().add(const Duration(days: 30));
//     String selectedIcon = template?['icon'] ?? '🎯';
//     final icons = ['🎯', '🏠', '🚗', '✈️', '💻', '📱', '🎓', '💍', '🏖️', '💰', '🛡️', '🎮'];

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//             left: 24,
//             right: 24,
//             top: 20,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Text(
//                       template != null ? 'Create from Template' : 'New Goal',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     if (template != null) ...[
//                       const Spacer(),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryColor.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           'Template',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppTheme.primaryColor,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: icons
//                       .map(
//                         (icon) => GestureDetector(
//                           onTap: () => setModalState(() => selectedIcon = icon),
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: selectedIcon == icon
//                                   ? AppTheme.primaryColor.withValues(alpha: 0.1)
//                                   : Colors.transparent,
//                               borderRadius: BorderRadius.circular(10),
//                               border: selectedIcon == icon
//                                   ? Border.all(
//                                       color: AppTheme.primaryColor,
//                                       width: 2,
//                                     )
//                                   : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
//                             ),
//                             child: Text(
//                               icon,
//                               style: const TextStyle(fontSize: 20),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(
//                     labelText: 'Goal Title',
//                     hintText: 'e.g., New Car',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: amountController,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     labelText: 'Target Amount',
//                     prefixText: '$_currencySymbol ',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 InkWell(
//                   onTap: () async {
//                     final date = await showDatePicker(
//                       context: context,
//                       initialDate: selectedDate,
//                       firstDate: DateTime.now(),
//                       lastDate: DateTime.now().add(const Duration(days: 3650)),
//                     );
//                     if (date != null) setModalState(() => selectedDate = date);
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.calendar_today, size: 20),
//                         const SizedBox(width: 12),
//                         Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
//                         const Spacer(),
//                         Text(
//                           '${selectedDate.difference(DateTime.now()).inDays} days',
//                           style: const TextStyle(
//                             color: AppTheme.textSecondary,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: FilledButton(
//                     onPressed: () async {
//                       if (titleController.text.isNotEmpty &&
//                           amountController.text.isNotEmpty) {
//                         await _dataService.insertGoal(
//                           Goal(
//                             title: titleController.text,
//                             targetAmount: double.parse(amountController.text),
//                             deadline: selectedDate,
//                             icon: selectedIcon,
//                           ),
//                         );
//                         if (context.mounted) {
//                           Navigator.pop(context);
//                           await _loadGoals();
//                         }
//                       }
//                     },
//                     style: FilledButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text('Create Goal'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredGoals = _filteredGoals;
    
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header with stats
//             Container(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Goals',
//                         style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: _showGoalOptions,
//                         icon: const Icon(Icons.add_circle),
//                         color: AppTheme.primaryColor,
//                       ),
//                     ],
//                   ),
//                   if (_goals.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     _buildStatsRow(),
//                     const SizedBox(height: 16),
//                     _buildFilterChips(),
//                   ],
//                 ],
//               ),
//             ).animate().fadeIn(duration: 400.ms),
            
//             // Goals list
//             Expanded(
//               child: filteredGoals.isEmpty
//                   ? _goals.isEmpty
//                       ? EmptyState(
//                           svgPath: 'assets/svgs/no-goals.svg',
//                           title: 'No Goals Yet',
//                           message:
//                               'Set financial goals to track your progress and stay motivated',
//                           actionText: 'Create Goal',
//                           onAction: _showGoalOptions,
//                         )
//                       : _buildEmptyFilter()
//                   : ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       itemCount: filteredGoals.length,
//                       itemBuilder: (context, index) {
//                         final goal = filteredGoals[index];
//                         return Dismissible(
//                           key: Key(goal.id!),
//                           direction: DismissDirection.endToStart,
//                           background: Container(
//                             margin: const EdgeInsets.only(bottom: 16),
//                             decoration: BoxDecoration(
//                               color: AppTheme.errorColor,
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             alignment: Alignment.centerRight,
//                             padding: const EdgeInsets.only(right: 20),
//                             child: const Icon(
//                               Icons.delete,
//                               color: Colors.white,
//                             ),
//                           ),
//                           onDismissed: (_) async {
//                             await _dataService.deleteGoal(goal.id!);
//                             await _loadGoals();
//                           },
//                           child: GestureDetector(
//                             onTap: () => _showGoalDetails(goal),
//                             child: _buildGoalCard(goal, index),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsRow() {
//     final totalGoals = _goals.length;
//     final completedGoals = _goals.where((g) => g.progress >= 1.0).length;
//     final totalTarget = _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
//     final totalSaved = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

//     return Row(
//       children: [
//         Expanded(child: _buildStatCard('Total Goals', totalGoals.toString(), Icons.flag)),
//         const SizedBox(width: 12),
//         Expanded(child: _buildStatCard('Completed', completedGoals.toString(), Icons.check_circle)),
//         const SizedBox(width: 12),
//         Expanded(child: _buildStatCard('Progress', '${totalTarget > 0 ? ((totalSaved / totalTarget) * 100).toInt() : 0}%', Icons.trending_up)),
//       ],
//     );
//   }

//   Widget _buildStatCard(String label, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [AppTheme.cardShadow],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: AppTheme.primaryColor, size: 20),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 11,
//               color: AppTheme.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChips() {
//     final filters = ['All', 'Active', 'Completed', 'Short-term', 'Long-term'];
    
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: filters.map((filter) {
//           final isSelected = _selectedFilter == filter;
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: FilterChip(
//               label: Text(filter),
//               selected: isSelected,
//               onSelected: (selected) {
//                 setState(() {
//                   _selectedFilter = filter;
//                 });
//               },
//               backgroundColor: Colors.transparent,
//               selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
//               checkmarkColor: AppTheme.primaryColor,
//               labelStyle: TextStyle(
//                 color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//               side: BorderSide(
//                 color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildEmptyFilter() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.filter_list_off,
//             size: 64,
//             color: Colors.grey.withValues(alpha: 0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No goals match this filter',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               color: AppTheme.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: () => setState(() => _selectedFilter = 'All'),
//             child: const Text('Show All Goals'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showGoalDetails(Goal goal) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.8,
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Text(goal.icon, style: const TextStyle(fontSize: 32)),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           goal.title,
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       PopupMenuButton(
//                         icon: const Icon(Icons.more_vert),
//                         itemBuilder: (context) => [
//                           PopupMenuItem(
//                             child: const Row(
//                               children: [
//                                 Icon(Icons.add_circle_outline),
//                                 SizedBox(width: 8),
//                                 Text('Add Funds'),
//                               ],
//                             ),
//                             onTap: () => Future.delayed(
//                               Duration.zero,
//                               () => _showAddFundsSheet(goal),
//                             ),
//                           ),
//                           PopupMenuItem(
//                             child: const Row(
//                               children: [
//                                 Icon(Icons.edit),
//                                 SizedBox(width: 8),
//                                 Text('Edit Goal'),
//                               ],
//                             ),
//                             onTap: () => Future.delayed(
//                               Duration.zero,
//                               () => _showEditGoalSheet(goal),
//                             ),
//                           ),
//                           PopupMenuItem(
//                             child: const Row(
//                               children: [
//                                 Icon(Icons.copy),
//                                 SizedBox(width: 8),
//                                 Text('Duplicate'),
//                               ],
//                             ),
//                             onTap: () => Future.delayed(
//                               Duration.zero,
//                               () => _duplicateGoal(goal),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildProgressSection(goal),
//                     const SizedBox(height: 24),
//                     _buildTimelineSection(goal),
//                     const SizedBox(height: 24),
//                     _buildQuickActions(goal),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressSection(Goal goal) {
//     final remaining = goal.targetAmount - goal.currentAmount;
//     final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
//     final dailyTarget = remaining > 0 && daysLeft > 0 ? remaining / daysLeft : 0;

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.primaryColor.withValues(alpha: 0.1),
//             AppTheme.secondaryColor.withValues(alpha: 0.1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Progress Overview',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Current Amount',
//                       style: const TextStyle(
//                         color: AppTheme.textSecondary,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Text(
//                       '$_currencySymbol${goal.currentAmount.toStringAsFixed(0)}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Remaining',
//                       style: const TextStyle(
//                         color: AppTheme.textSecondary,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Text(
//                       '$_currencySymbol${remaining.toStringAsFixed(0)}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: goal.progress.clamp(0.0, 1.0),
//               minHeight: 12,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation(
//                 goal.progress >= 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${(goal.progress * 100).toStringAsFixed(1)}% completed',
//                 style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
//               ),
//               if (dailyTarget > 0)
//                 Text(
//                   '$_currencySymbol${dailyTarget.toStringAsFixed(0)}/day needed',
//                   style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimelineSection(Goal goal) {
//     final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
//     final isOverdue = daysLeft < 0;
    
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Timeline',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Icon(
//                 isOverdue ? Icons.warning : Icons.schedule,
//                 color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       isOverdue ? 'Overdue' : '$daysLeft days remaining',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: isOverdue ? AppTheme.errorColor : null,
//                       ),
//                     ),
//                     Text(
//                       'Target: ${DateFormat('MMM dd, yyyy').format(goal.deadline)}',
//                       style: const TextStyle(
//                         color: AppTheme.textSecondary,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions(Goal goal) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Quick Actions',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _showAddFundsSheet(goal);
//                 },
//                 icon: const Icon(Icons.add_circle_outline),
//                 label: const Text('Add Funds'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.primaryColor,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _showEditGoalSheet(goal);
//                 },
//                 icon: const Icon(Icons.edit),
//                 label: const Text('Edit'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   void _showEditGoalSheet(Goal goal) {
//     // Implementation for editing goal
//     _showAddGoalSheet(); // Placeholder - would need to populate with existing data
//   }

//   void _showAddFundsSheet(Goal goal) {
//     final amountController = TextEditingController();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Add Funds to ${goal.title}',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: amountController,
//               keyboardType: TextInputType.number,
//               autofocus: true,
//               decoration: InputDecoration(
//                 labelText: 'Amount',
//                 prefixText: '$_currencySymbol ',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: () async {
//                   if (amountController.text.isNotEmpty) {
//                     final oldProgress = goal.progress;
//                     final newAmount =
//                         goal.currentAmount +
//                         double.parse(amountController.text);
//                     final updatedGoal = goal.copyWith(currentAmount: newAmount);

//                     await _dataService.updateGoal(updatedGoal);

//                     // Check milestones
//                     final newProgress = updatedGoal.progress;
//                     _checkMilestone(oldProgress, newProgress, goal.title);

//                     if (context.mounted) {
//                       Navigator.pop(context);
//                       await _loadGoals();
//                     }
//                   }
//                 },
//                 child: const Text('Add Funds'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//     final amountController = TextEditingController();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Add Funds to ${goal.title}',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: amountController,
//               keyboardType: TextInputType.number,
//               autofocus: true,
//               decoration: InputDecoration(
//                 labelText: 'Amount',
//                 prefixText: '$_currencySymbol ',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: () async {
//                   if (amountController.text.isNotEmpty) {
//                     final oldProgress = goal.progress;
//                     final newAmount =
//                         goal.currentAmount +
//                         double.parse(amountController.text);
//                     final updatedGoal = goal.copyWith(currentAmount: newAmount);

//                     await _dataService.updateGoal(updatedGoal);

//                     // Check milestones
//                     final newProgress = updatedGoal.progress;
//                     _checkMilestone(oldProgress, newProgress, goal.title);

//                     if (context.mounted) {
//                       Navigator.pop(context);
//                       await _loadGoals();
//                     }
//                   }
//                 },
//                 child: const Text('Add Funds'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _checkMilestone(
//     double oldProgress,
//     double newProgress,
//     String goalTitle,
//   ) {
//     final milestones = [0.25, 0.5, 0.75, 1.0];

//     for (var milestone in milestones) {
//       if (oldProgress < milestone && newProgress >= milestone) {
//         HapticService.medium();

//         String message;
//         String emoji;
//         if (milestone == 1.0) {
//           message = 'Goal Complete! You reached your $goalTitle goal!';
//           emoji = '🎉';
//         } else {
//           message =
//               '${(milestone * 100).toInt()}% of your $goalTitle goal reached!';
//           emoji = milestone == 0.75
//               ? '🔥'
//               : milestone == 0.5
//               ? '💪'
//               : '🌟';
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Text(emoji, style: const TextStyle(fontSize: 24)),
//                 const SizedBox(width: 12),
//                 Expanded(child: Text(message)),
//               ],
//             ),
//             backgroundColor: AppTheme.successColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             duration: const Duration(seconds: 3),
//           ),
//         );
//         break;
//       }
//     }
//   }

//   Widget _buildGoalCard(Goal goal, int index) {
//     final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
//     final isCompleted = goal.progress >= 1.0;
//     final isOverdue = daysLeft < 0 && !isCompleted;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         gradient: isCompleted
//             ? LinearGradient(
//                 colors: [
//                   AppTheme.successColor.withValues(alpha: 0.1),
//                   AppTheme.successColor.withValues(alpha: 0.05),
//                 ],
//               )
//             : isOverdue
//                 ? LinearGradient(
//                     colors: [
//                       AppTheme.errorColor.withValues(alpha: 0.1),
//                       AppTheme.errorColor.withValues(alpha: 0.05),
//                     ],
//                   )
//                 : LinearGradient(
//                     colors: [
//                       AppTheme.primaryColor.withValues(alpha: 0.05),
//                       AppTheme.secondaryColor.withValues(alpha: 0.05),
//                     ],
//                   ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [AppTheme.cardShadow],
//         border: Border.all(
//           color: isCompleted
//               ? AppTheme.successColor.withValues(alpha: 0.3)
//               : isOverdue
//                   ? AppTheme.errorColor.withValues(alpha: 0.3)
//                   : AppTheme.primaryColor.withValues(alpha: 0.1),
//           width: 1,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Status badge
//                   if (isCompleted || isOverdue)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isCompleted ? AppTheme.successColor : AppTheme.errorColor,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             isCompleted ? Icons.check_circle : Icons.warning,
//                             color: Colors.white,
//                             size: 16,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             isCompleted ? 'Completed!' : 'Overdue',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ).animate(onPlay: (controller) => isCompleted ? controller.repeat() : null)
//                         .shimmer(
//                           duration: 2000.ms,
//                           color: Colors.white.withValues(alpha: 0.5),
//                         ),
                  
//                   if (isCompleted || isOverdue) const SizedBox(height: 12),
                  
//                   // Goal header
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withValues(alpha: 0.8),
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Text(goal.icon, style: const TextStyle(fontSize: 24)),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               goal.title,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               isOverdue
//                                   ? '${daysLeft.abs()} days overdue'
//                                   : '$daysLeft days left',
//                               style: TextStyle(
//                                 color: isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
//                                 fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             '$_currencySymbol${goal.currentAmount.toStringAsFixed(0)}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             'of $_currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: AppTheme.textSecondary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Progress section
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${(goal.progress * 100).toStringAsFixed(0)}% completed',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       if (goal.progress < 1.0)
//                         Text(
//                           '$_currencySymbol${(goal.targetAmount - goal.currentAmount).toStringAsFixed(0)} to go',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: AppTheme.textSecondary,
//                           ),
//                         ),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 8),
                  
//                   // Progress bar
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: LinearProgressIndicator(
//                       value: goal.progress.clamp(0.0, 1.0),
//                       minHeight: 10,
//                       backgroundColor: Colors.white.withValues(alpha: 0.3),
//                       valueColor: AlwaysStoppedAnimation(
//                         isCompleted
//                             ? AppTheme.successColor
//                             : isOverdue
//                                 ? AppTheme.errorColor
//                                 : AppTheme.primaryColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Decorative elements
//             Positioned(
//               top: -20,
//               right: -20,
//               child: Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: -10,
//               left: -10,
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.05),
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
//   }

//   void _duplicateGoal(Goal goal) async {
//     final newGoal = Goal(
//       title: '${goal.title} (Copy)',
//       targetAmount: goal.targetAmount,
//       deadline: DateTime.now().add(const Duration(days: 365)),
//       icon: goal.icon,
//     );
    
//     await _dataService.insertGoal(newGoal);
//     await _loadGoals();
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Goal duplicated successfully'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }
