import 'dart:async';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/category.dart';
import 'data_service.dart';

class AppStateService {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  final DataService _dataService = DataService();
  
  // Cached data
  List<Transaction>? _transactions;
  List<Goal>? _goals;
  List<Category>? _categories;
  
  // Cache timestamps
  DateTime? _transactionsLastUpdated;
  DateTime? _goalsLastUpdated;
  DateTime? _categoriesLastUpdated;
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Stream controllers for reactive updates
  final _transactionsController = StreamController<List<Transaction>>.broadcast();
  final _goalsController = StreamController<List<Goal>>.broadcast();
  
  Stream<List<Transaction>> get transactionsStream => _transactionsController.stream;
  Stream<List<Goal>> get goalsStream => _goalsController.stream;

  // Get transactions with caching
  Future<List<Transaction>> getTransactions({bool forceRefresh = false}) async {
    if (forceRefresh || _shouldRefreshTransactions()) {
      _transactions = await _dataService.getTransactions();
      _transactionsLastUpdated = DateTime.now();
      _transactionsController.add(_transactions!);
    }
    return _transactions ?? [];
  }

  // Get goals with caching
  Future<List<Goal>> getGoals({bool forceRefresh = false}) async {
    if (forceRefresh || _shouldRefreshGoals()) {
      _goals = await _dataService.getGoals();
      _goalsLastUpdated = DateTime.now();
      _goalsController.add(_goals!);
    }
    return _goals ?? [];
  }

  // Get categories with caching
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    if (forceRefresh || _shouldRefreshCategories()) {
      _categories = await _dataService.getCategories();
      _categoriesLastUpdated = DateTime.now();
    }
    return _categories ?? [];
  }

  // Invalidate specific cache when data changes
  void invalidateTransactions() {
    _transactions = null;
    _transactionsLastUpdated = null;
  }

  void invalidateGoals() {
    _goals = null;
    _goalsLastUpdated = null;
  }

  void invalidateCategories() {
    _categories = null;
    _categoriesLastUpdated = null;
  }

  // Clear all cache
  void clearCache() {
    _transactions = null;
    _goals = null;
    _categories = null;
    _transactionsLastUpdated = null;
    _goalsLastUpdated = null;
    _categoriesLastUpdated = null;
  }

  // Check if cache should be refreshed
  bool _shouldRefreshTransactions() {
    return _transactions == null || 
           _transactionsLastUpdated == null ||
           DateTime.now().difference(_transactionsLastUpdated!) > _cacheDuration;
  }

  bool _shouldRefreshGoals() {
    return _goals == null || 
           _goalsLastUpdated == null ||
           DateTime.now().difference(_goalsLastUpdated!) > _cacheDuration;
  }

  bool _shouldRefreshCategories() {
    return _categories == null || 
           _categoriesLastUpdated == null ||
           DateTime.now().difference(_categoriesLastUpdated!) > _cacheDuration;
  }

  void dispose() {
    _transactionsController.close();
    _goalsController.close();
  }
}
