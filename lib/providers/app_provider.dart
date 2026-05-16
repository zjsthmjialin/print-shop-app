import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/icloud_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final StorageService _storage = StorageService.instance;

  List<Customer> _customers = [];
  List<Copier> _copiers = [];
  List<Transaction> _transactions = [];
  List<InventoryItem> _inventoryItems = [];
  List<ServiceType> _serviceTypes = [];

  double _todayIncome = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;
  double _totalUnpaid = 0;
  double _totalPaid = 0;
  double _totalPrepaid = 0;

  bool _isLoading = true;

  List<Customer> get customers => _customers;
  List<Copier> get copiers => _copiers;
  List<Transaction> get recentTransactions => _transactions;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<ServiceType> get serviceTypes => _serviceTypes;
  double get todayIncome => _todayIncome;
  double get monthIncome => _monthIncome;
  double get monthExpense => _monthExpense;
  double get totalUnpaid => _totalUnpaid;
  double get totalPaid => _totalPaid;
  double get totalPrepaid => _totalPrepaid;
  double get totalOwed => _totalUnpaid;
  bool get isLoading => _isLoading;

  List<ServiceType> get activeServiceTypes => _serviceTypes.where((s) => s.isActive).toList();
  List<Copier> get idleCopiers => _copiers.where((c) => c.status == CopierStatus.idle).toList();
  List<InventoryItem> get lowStockItems => _inventoryItems.where((i) => i.isLowStock).toList();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // 尝试初始化 iCloud Drive
    final icloud = ICloudService();
    await icloud.init();

    // 初始化存储服务（优先使用 iCloud 路径）
    await _storage.init(customPath: icloud.documentsPath);

    // 加载存储的数据
    _customers = await _storage.loadCustomers();
    _copiers = await _storage.loadCopiers();
    _transactions = await _storage.loadTransactions();
    _inventoryItems = await _storage.loadInventory();
    _serviceTypes = await _storage.loadServiceTypes();

    // 如果没有服务类型，初始化默认类型
    if (_serviceTypes.isEmpty) {
      _db.initDefaultServiceTypes().then((_) async {
        _serviceTypes = await _db.getAllServiceTypes();
        await _storage.saveServiceTypes(_serviceTypes);
      });
    } else {
      // 同步到内存数据库
      for (final customer in _customers) {
        await _db.insertCustomer(customer);
      }
      for (final copier in _copiers) {
        await _db.insertCopier(copier);
      }
      for (final transaction in _transactions) {
        await _db.insertTransaction(transaction);
      }
      for (final item in _inventoryItems) {
        await _db.insertInventoryItem(item);
      }
      for (final serviceType in _serviceTypes) {
        await _db.insertServiceType(serviceType);
      }
    }

    await loadStatistics();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics() async {
    _todayIncome = _calculateTodayIncome();
    _monthIncome = _calculateMonthIncome();
    _monthExpense = _calculateMonthExpense();
    _totalUnpaid = _calculateTotalUnpaid();
    _totalPaid = _calculateTotalPaid();
    _totalPrepaid = _calculateTotalPrepaid();
    notifyListeners();
  }

  double _calculateTodayIncome() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    double total = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income && t.amount > 0 && t.createdAt.isAfter(startOfDay)) {
        total += t.amount;
      }
    }
    return total;
  }

  double _calculateMonthIncome() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income && t.amount > 0 && t.createdAt.isAfter(startOfMonth)) {
        total += t.amount;
      }
    }
    return total;
  }

  double _calculateMonthExpense() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.expense && t.amount < 0 && t.createdAt.isAfter(startOfMonth)) {
        total += t.amount.abs();
      }
    }
    return total;
  }

  double _calculateTotalUnpaid() {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId != null && t.type == TransactionType.income && !t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  double _calculateTotalPaid() {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId != null && t.type == TransactionType.income && t.amount > 0) {
        total += t.amount;
      }
    }
    return total - _totalUnpaid;
  }

  double _calculateTotalPrepaid() {
    double total = 0;
    for (final c in _customers) {
      total += c.prepaidBalance;
    }
    return total > 0 ? total : 0;
  }

  // ============ 服务类型操作 ============

  Future<void> loadServiceTypes() async {
    _serviceTypes = await _db.getAllServiceTypes();
    await _storage.saveServiceTypes(_serviceTypes);
    notifyListeners();
  }

  Future<void> addServiceType(ServiceType serviceType) async {
    await _db.insertServiceType(serviceType);
    await loadServiceTypes();
  }

  Future<void> updateServiceType(ServiceType serviceType) async {
    await _db.updateServiceType(serviceType);
    await loadServiceTypes();
  }

  Future<void> deleteServiceType(int id) async {
    await _db.deleteServiceType(id);
    await loadServiceTypes();
  }

  List<ServiceType> getServiceTypesByCategory(ExpenseCategory category) {
    return _serviceTypes.where((s) => s.category == category && s.isActive).toList();
  }

  ServiceType? getServiceTypeById(int id) {
    return _serviceTypes.where((s) => s.id == id).firstOrNull;
  }

  // ============ 客户操作 ============

  Future<void> addCustomer(Customer customer) async {
    await _db.insertCustomer(customer);
    _customers = await _db.getAllCustomers();
    await _storage.saveCustomers(_customers);
    await loadStatistics();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    _customers = await _db.getAllCustomers();
    await _storage.saveCustomers(_customers);
  }

  Future<void> deleteCustomer(int id) async {
    await _db.deleteCustomer(id);
    _customers = await _db.getAllCustomers();
    await _storage.saveCustomers(_customers);
  }

  Future<void> addCustomerPrepaid(int customerId, double amount) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final updated = _customers[index].copyWith(
        prepaidBalance: _customers[index].prepaidBalance + amount,
      );
      await updateCustomer(updated);
    }
  }

  Future<double> getCustomerUnpaidAmount(int customerId) async {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId == customerId && t.type == TransactionType.income && !t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  Future<double> getCustomerPaidAmount(int customerId) async {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId == customerId && t.type == TransactionType.income && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  // ============ 复印机操作 ============

  Future<void> addCopier(Copier copier) async {
    await _db.insertCopier(copier);
    _copiers = await _db.getAllCopiers();
    await _storage.saveCopiers(_copiers);
    notifyListeners();
  }

  Future<void> updateCopier(Copier copier) async {
    await _db.updateCopier(copier);
    _copiers = await _db.getAllCopiers();
    await _storage.saveCopiers(_copiers);
  }

  // ============ 交易操作 ============

  Future<void> addTransaction(Transaction transaction) async {
    await _db.insertTransaction(transaction);
    _transactions = await _db.getAllTransactions();
    await _storage.saveTransactions(_transactions);
    await loadStatistics();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction);
    _transactions = await _db.getAllTransactions();
    await _storage.saveTransactions(_transactions);
    await loadStatistics();
  }

  Future<List<Transaction>> getAllTransactions() async {
    return _transactions;
  }

  Future<List<Transaction>> getTransactionsByCustomer(int customerId) async {
    return _transactions.where((t) => t.customerId == customerId).toList();
  }

  // ============ 库存操作 ============

  Future<void> addInventoryItem(InventoryItem item) async {
    await _db.insertInventoryItem(item);
    _inventoryItems = await _db.getAllInventoryItems();
    await _storage.saveInventory(_inventoryItems);
    notifyListeners();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _db.updateInventoryItem(item);
    _inventoryItems = await _db.getAllInventoryItems();
    await _storage.saveInventory(_inventoryItems);
  }

  // ============ 统计操作 ============

  Future<Map<ExpenseCategory, double>> getCategorySummary() async {
    final summary = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      double total = 0;
      for (final t in _transactions) {
        if (t.expenseCategory == category && t.amount > 0) {
          total += t.amount;
        }
      }
      summary[category] = total;
    }
    return summary;
  }

  // ============ 数据导出/导入 ============

  Future<String> exportData() async {
    return await _storage.exportAllData();
  }

  Future<void> importData(String jsonData) async {
    await _storage.importAllData(jsonData);
    await initialize();
  }

  // ============ 辅助方法 ============

  Customer? getCustomerById(int id) {
    return _customers.where((c) => c.id == id).firstOrNull;
  }

  Copier? getCopierById(int id) {
    return _copiers.where((c) => c.id == id).firstOrNull;
  }
}
