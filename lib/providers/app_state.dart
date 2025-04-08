import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/stock.dart';
import '../models/daily_record.dart';
import '../models/expense.dart';
import '../services/data_manager.dart';

class AppState extends ChangeNotifier {
  final DataManager _dataManager = DataManager();
  
  List<Cart> _carts = [];
  List<Stock> _stocks = [];
  List<DailyRecord> _dailyRecords = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  // Getters
  List<Cart> get carts => _carts;
  List<Stock> get stocks => _stocks;
  List<DailyRecord> get dailyRecords => _dailyRecords;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  // Initialisation
  Future<void> initialize() async {
    _isLoading = true;
    // notifyListeners();
    
    await loadAll();
    
    _isLoading = false;
    notifyListeners();
  }

  // Chargement de toutes les données
  Future<void> loadAll() async {
    await loadCarts();
    await loadStocks();
    await loadDailyRecords();
    await loadExpenses();
  }

  // Méthodes pour les Chariots
  Future<void> loadCarts() async {
    _carts = await _dataManager.getCarts();
    notifyListeners();
  }

  Future<Cart> addCart(Cart cart) async {
    final newCart = await _dataManager.addCart(cart);
    await loadCarts();
    return newCart;
  }

  Future<void> updateCart(Cart cart) async {
    await _dataManager.updateCart(cart);
    await loadCarts();
  }

  Future<void> deleteCart(String id) async {
    await _dataManager.deleteCart(id);
    await loadCarts();
  }

  // Méthodes pour le Stock
  Future<void> loadStocks() async {
    _stocks = await _dataManager.getStocks();
    _stocks.sort((a, b) => b.arrivalDate.compareTo(a.arrivalDate)); // Le plus récent d'abord
    notifyListeners();
  }

  Future<Stock> addStock(Stock stock) async {
    final newStock = await _dataManager.addStock(stock);
    await loadStocks();
    return newStock;
  }

  Future<void> updateStock(Stock stock) async {
    await _dataManager.updateStock(stock);
    await loadStocks();
  }

  Future<void> deleteStock(String id) async {
    await _dataManager.deleteStock(id);
    await loadStocks();
  }

  // Méthodes pour les Fiches Journalières
  Future<void> loadDailyRecords() async {
    _dailyRecords = await _dataManager.getDailyRecords();
    _dailyRecords.sort((a, b) => b.date.compareTo(a.date)); // Le plus récent d'abord
    notifyListeners();
  }

  Future<DailyRecord> addDailyRecord(DailyRecord record) async {
    final newRecord = await _dataManager.addDailyRecord(record);
    await loadDailyRecords();
    return newRecord;
  }

  Future<void> updateDailyRecord(DailyRecord record) async {
    await _dataManager.updateDailyRecord(record);
    await loadDailyRecords();
  }

  Future<void> deleteDailyRecord(String id) async {
    await _dataManager.deleteDailyRecord(id);
    await loadDailyRecords();
  }

  // Méthodes pour les Dépenses
  Future<void> loadExpenses() async {
    _expenses = await _dataManager.getExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date)); // Le plus récent d'abord
    notifyListeners();
  }

  Future<Expense> addExpense(Expense expense) async {
    final newExpense = await _dataManager.addExpense(expense);
    await loadExpenses();
    return newExpense;
  }

  Future<void> updateExpense(Expense expense) async {
    await _dataManager.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _dataManager.deleteExpense(id);
    await loadExpenses();
  }

  // Méthodes pour le Dashboard
  Future<double> getTotalRevenue(DateTime? startDate, DateTime? endDate) {
    return _dataManager.getTotalRevenue(startDate, endDate);
  }

  Future<double> getTotalExpenses(DateTime? startDate, DateTime? endDate) {
    return _dataManager.getTotalExpenses(startDate, endDate);
  }

  Future<double> getCurrentStockQuantity() {
    return _dataManager.getCurrentStockQuantity();
  }

  // Pour obtenir un chariot à partir de son ID
  Cart? getCartById(String id) {
    try {
      return _carts.firstWhere((cart) => cart.id == id);
    } catch (e) {
      return null;
    }
  }

  // Récupérer les fiches journalières pour un chariot spécifique
  List<DailyRecord> getDailyRecordsForCart(String cartId) {
    return _dailyRecords.where((record) => record.cartId == cartId).toList();
  }

  // Récupérer les fiches journalières pour une période spécifique
  List<DailyRecord> getDailyRecordsForPeriod(DateTime startDate, DateTime endDate) {
    return _dailyRecords
        .where((record) => 
            record.date.isAfter(startDate.subtract(Duration(days: 1))) && 
            record.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
  }

  // Récupérer les dépenses pour une période spécifique
  List<Expense> getExpensesForPeriod(DateTime startDate, DateTime endDate) {
    return _expenses
        .where((expense) => 
            expense.date.isAfter(startDate.subtract(Duration(days: 1))) && 
            expense.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
  }

  // Récupérer les dépenses par catégorie pour une période spécifique
  Future<Map<String, double>> getExpensesByCategory(DateTime? startDate, DateTime? endDate) async {
    // S'assurer que les dépenses sont chargées
    await loadExpenses();
    
    List<Expense> filteredExpenses = _expenses;
    
    if (startDate != null && endDate != null) {
      filteredExpenses = getExpensesForPeriod(startDate, endDate);
    }
    
    Map<String, double> result = {};
    for (var expense in filteredExpenses) {
      if (result.containsKey(expense.category)) {
        result[expense.category] = result[expense.category]! + expense.amount;
      } else {
        result[expense.category] = expense.amount;
      }
    }
    
    return result;
  }
}