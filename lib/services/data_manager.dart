import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/cart.dart';
import '../models/stock.dart';
import '../models/daily_record.dart';
import '../models/expense.dart';

class DataManager {
  static const String _cartKey = 'carts';
  static const String _stockKey = 'stocks';
  static const String _dailyRecordKey = 'daily_records';
  static const String _expenseKey = 'expenses';
  
  static final DataManager _instance = DataManager._internal();
  final Uuid _uuid = Uuid();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  // Générer un nouvel ID unique
  String generateId() {
    return _uuid.v4();
  }

  // CRUD pour les Chariots
  Future<List<Cart>> getCarts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cartsJson = prefs.getString(_cartKey);
    
    if (cartsJson == null) {
      return [];
    }
    
    List<dynamic> cartsList = jsonDecode(cartsJson);
    return cartsList.map((cart) => Cart.fromJson(cart)).toList();
  }

  Future<void> saveCarts(List<Cart> carts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cartsJson = jsonEncode(carts.map((cart) => cart.toJson()).toList());
    await prefs.setString(_cartKey, cartsJson);
  }

  Future<Cart> addCart(Cart cart) async {
    List<Cart> carts = await getCarts();
    // Assure-toi que l'ID est unique
    String id = cart.id.isEmpty ? generateId() : cart.id;
    Cart newCart = cart.copyWith(id: id);
    
    carts.add(newCart);
    await saveCarts(carts);
    return newCart;
  }

  Future<void> updateCart(Cart cart) async {
    List<Cart> carts = await getCarts();
    final index = carts.indexWhere((c) => c.id == cart.id);
    
    if (index >= 0) {
      carts[index] = cart;
      await saveCarts(carts);
    }
  }

  Future<void> deleteCart(String id) async {
    List<Cart> carts = await getCarts();
    carts.removeWhere((cart) => cart.id == id);
    await saveCarts(carts);
  }

  // CRUD pour le Stock
  Future<List<Stock>> getStocks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stocksJson = prefs.getString(_stockKey);
    
    if (stocksJson == null) {
      return [];
    }
    
    List<dynamic> stocksList = jsonDecode(stocksJson);
    return stocksList.map((stock) => Stock.fromJson(stock)).toList();
  }

  Future<void> saveStocks(List<Stock> stocks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String stocksJson = jsonEncode(stocks.map((stock) => stock.toJson()).toList());
    await prefs.setString(_stockKey, stocksJson);
  }

  Future<Stock> addStock(Stock stock) async {
    List<Stock> stocks = await getStocks();
    String id = stock.id.isEmpty ? generateId() : stock.id;
    Stock newStock = stock.copyWith(id: id);
    
    stocks.add(newStock);
    await saveStocks(stocks);
    return newStock;
  }

  Future<void> updateStock(Stock stock) async {
    List<Stock> stocks = await getStocks();
    final index = stocks.indexWhere((s) => s.id == stock.id);
    
    if (index >= 0) {
      stocks[index] = stock;
      await saveStocks(stocks);
    }
  }

  Future<void> deleteStock(String id) async {
    List<Stock> stocks = await getStocks();
    stocks.removeWhere((stock) => stock.id == id);
    await saveStocks(stocks);
  }

  // CRUD pour les Fiches Journalières
  Future<List<DailyRecord>> getDailyRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? recordsJson = prefs.getString(_dailyRecordKey);
    
    if (recordsJson == null) {
      return [];
    }
    
    List<dynamic> recordsList = jsonDecode(recordsJson);
    return recordsList.map((record) => DailyRecord.fromJson(record)).toList();
  }

  Future<void> saveDailyRecords(List<DailyRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String recordsJson = jsonEncode(records.map((record) => record.toJson()).toList());
    await prefs.setString(_dailyRecordKey, recordsJson);
  }

  Future<DailyRecord> addDailyRecord(DailyRecord record) async {
    List<DailyRecord> records = await getDailyRecords();
    String id = record.id.isEmpty ? generateId() : record.id;
    DailyRecord newRecord = record.copyWith(id: id);
    
    records.add(newRecord);
    await saveDailyRecords(records);
    return newRecord;
  }

  Future<void> updateDailyRecord(DailyRecord record) async {
    List<DailyRecord> records = await getDailyRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    
    if (index >= 0) {
      records[index] = record;
      await saveDailyRecords(records);
    }
  }

  Future<void> deleteDailyRecord(String id) async {
    List<DailyRecord> records = await getDailyRecords();
    records.removeWhere((record) => record.id == id);
    await saveDailyRecords(records);
  }

  // CRUD pour les Dépenses
  Future<List<Expense>> getExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString(_expenseKey);
    
    if (expensesJson == null) {
      return [];
    }
    
    List<dynamic> expensesList = jsonDecode(expensesJson);
    return expensesList.map((expense) => Expense.fromJson(expense)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = jsonEncode(expenses.map((expense) => expense.toJson()).toList());
    await prefs.setString(_expenseKey, expensesJson);
  }

  Future<Expense> addExpense(Expense expense) async {
    List<Expense> expenses = await getExpenses();
    String id = expense.id.isEmpty ? generateId() : expense.id;
    Expense newExpense = expense.copyWith(id: id);
    
    expenses.add(newExpense);
    await saveExpenses(expenses);
    return newExpense;
  }

  Future<void> updateExpense(Expense expense) async {
    List<Expense> expenses = await getExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    
    if (index >= 0) {
      expenses[index] = expense;
      await saveExpenses(expenses);
    }
  }

  Future<void> deleteExpense(String id) async {
    List<Expense> expenses = await getExpenses();
    expenses.removeWhere((expense) => expense.id == id);
    await saveExpenses(expenses);
  }

  // Méthodes pour le Dashboard
  Future<double> getTotalRevenue(DateTime? startDate, DateTime? endDate) async {
    List<DailyRecord> records = await getDailyRecords();
    
    if (startDate != null && endDate != null) {
      records = records.where((record) => 
        record.date.isAfter(startDate.subtract(Duration(days: 1))) && 
        record.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
    }
    
    double total = 0;
    for (var record in records) {
      total += record.amountCollected;
    }
    return total;
  }

  Future<double> getTotalExpenses(DateTime? startDate, DateTime? endDate) async {
    List<Expense> expenses = await getExpenses();
    
    if (startDate != null && endDate != null) {
      expenses = expenses.where((expense) => 
        expense.date.isAfter(startDate.subtract(Duration(days: 1))) && 
        expense.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
    }
    
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  Future<double> getCurrentStockQuantity() async {
    List<Stock> stocks = await getStocks();
    List<DailyRecord> records = await getDailyRecords();
    
    double totalStock = stocks.fold(0, (sum, stock) => sum + stock.quantity);
    double totalAssigned = records.fold(0, (sum, record) => sum + record.assignedQuantity);
    
    return totalStock - totalAssigned;
  }
}