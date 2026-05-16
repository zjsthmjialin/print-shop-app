import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/icloud_service.dart';

class AppProvider extends ChangeNotifier {
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
  String? _lastError;

  int _nextId = 1;

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
  String? get lastError => _lastError;

  List<ServiceType> get activeServiceTypes => _serviceTypes.where((s) => s.isActive).toList();
  List<Copier> get idleCopiers => _copiers.where((c) => c.status == CopierStatus.idle).toList();
  List<InventoryItem> get lowStockItems => _inventoryItems.where((i) => i.isLowStock).toList();

  int _allocateId() => _nextId++;

  void _initNextId() {
    final allIds = <int>[];
    for (final c in _customers) {
      if (c.id != null) allIds.add(c.id!);
    }
    for (final c in _copiers) {
      if (c.id != null) allIds.add(c.id!);
    }
    for (final t in _transactions) {
      if (t.id != null) allIds.add(t.id!);
    }
    for (final i in _inventoryItems) {
      if (i.id != null) allIds.add(i.id!);
    }
    for (final s in _serviceTypes) {
      if (s.id != null) allIds.add(s.id!);
    }
    _nextId = allIds.isEmpty ? 1 : allIds.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
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

      // 初始化 ID 计数器（从已有数据中的最大 ID 开始）
      _initNextId();

      // 如果没有服务类型，初始化默认类型
      if (_serviceTypes.isEmpty) {
        await _initDefaultServiceTypes();
      }

      await _loadStatistics();
    } catch (e) {
      _lastError = '初始化失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initDefaultServiceTypes() async {
    final defaults = [
      ServiceType(name: '黑白打印', category: ExpenseCategory.printFee, unitPrice: 0.2),
      ServiceType(name: '彩色打印', category: ExpenseCategory.printFee, unitPrice: 1.0),
      ServiceType(name: '复印', category: ExpenseCategory.printFee, unitPrice: 0.1),
      ServiceType(name: '扫描', category: ExpenseCategory.printFee, unitPrice: 1.0),
      ServiceType(name: '装订', category: ExpenseCategory.printFee, unitPrice: 5.0),
      ServiceType(name: '名片', category: ExpenseCategory.printFee, unitPrice: 0.5),
      ServiceType(name: '设计', category: ExpenseCategory.other, unitPrice: 100.0),
      ServiceType(name: '租赁复印', category: ExpenseCategory.rentalFee, unitPrice: 0.15),
      ServiceType(name: '配件销售', category: ExpenseCategory.accessoryFee, unitPrice: null),
      ServiceType(name: '办公用品', category: ExpenseCategory.officeSupply, unitPrice: null),
    ];

    for (final service in defaults) {
      _serviceTypes.add(service.copyWith(id: _allocateId()));
    }
    await _storage.saveServiceTypes(_serviceTypes);
  }

  Future<void> _loadStatistics() async {
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
      if (t.type == TransactionType.income && t.amount > 0 &&
          !t.createdAt.isBefore(startOfDay)) {
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
      if (t.type == TransactionType.income && t.amount > 0 &&
          !t.createdAt.isBefore(startOfMonth)) {
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
      if (t.type == TransactionType.expense && t.amount < 0 &&
          !t.createdAt.isBefore(startOfMonth)) {
        total += t.amount.abs();
      }
    }
    return total;
  }

  double _calculateTotalUnpaid() {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId != null && t.type == TransactionType.income &&
          !t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  double _calculateTotalPaid() {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId != null && t.type == TransactionType.income &&
          t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  double _calculateTotalPrepaid() {
    double total = 0;
    for (final c in _customers) {
      total += c.prepaidBalance;
    }
    return total > 0 ? total : 0;
  }

  // ============ 服务类型操作 ============

  Future<void> addServiceType(ServiceType serviceType) async {
    try {
      final withId = serviceType.copyWith(id: _allocateId());
      _serviceTypes.add(withId);
      await _storage.saveServiceTypes(_serviceTypes);
      notifyListeners();
    } catch (e) {
      _lastError = '添加服务类型失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateServiceType(ServiceType serviceType) async {
    try {
      final index = _serviceTypes.indexWhere((s) => s.id == serviceType.id);
      if (index != -1) {
        _serviceTypes[index] = serviceType;
      }
      await _storage.saveServiceTypes(_serviceTypes);
      notifyListeners();
    } catch (e) {
      _lastError = '更新服务类型失败: $e';
      notifyListeners();
    }
  }

  Future<void> deleteServiceType(int id) async {
    try {
      _serviceTypes.removeWhere((s) => s.id == id);
      await _storage.saveServiceTypes(_serviceTypes);
      notifyListeners();
    } catch (e) {
      _lastError = '删除服务类型失败: $e';
      notifyListeners();
    }
  }

  List<ServiceType> getServiceTypesByCategory(ExpenseCategory category) {
    return _serviceTypes.where((s) => s.category == category && s.isActive).toList();
  }

  ServiceType? getServiceTypeById(int id) {
    return _serviceTypes.where((s) => s.id == id).firstOrNull;
  }

  // ============ 客户操作 ============

  Future<void> addCustomer(Customer customer) async {
    try {
      final withId = customer.copyWith(id: _allocateId());
      _customers.add(withId);
      await _storage.saveCustomers(_customers);
      await _loadStatistics();
    } catch (e) {
      _lastError = '添加客户失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
      }
      await _storage.saveCustomers(_customers);
      await _loadStatistics();
    } catch (e) {
      _lastError = '更新客户失败: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      _customers.removeWhere((c) => c.id == id);
      await _storage.saveCustomers(_customers);
      await _loadStatistics();
    } catch (e) {
      _lastError = '删除客户失败: $e';
      notifyListeners();
    }
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
      if (t.customerId == customerId && t.type == TransactionType.income &&
          !t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  Future<double> getCustomerPaidAmount(int customerId) async {
    double total = 0;
    for (final t in _transactions) {
      if (t.customerId == customerId && t.type == TransactionType.income &&
          t.isPaid && t.amount > 0) {
        total += t.amount;
      }
    }
    return total;
  }

  // ============ 复印机操作 ============

  Future<void> addCopier(Copier copier) async {
    try {
      final withId = copier.copyWith(id: _allocateId());
      _copiers.add(withId);
      await _storage.saveCopiers(_copiers);
      notifyListeners();
    } catch (e) {
      _lastError = '添加复印机失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateCopier(Copier copier) async {
    try {
      final index = _copiers.indexWhere((c) => c.id == copier.id);
      if (index != -1) {
        _copiers[index] = copier;
      }
      await _storage.saveCopiers(_copiers);
      notifyListeners();
    } catch (e) {
      _lastError = '更新复印机失败: $e';
      notifyListeners();
    }
  }

  // ============ 交易操作 ============

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final withId = transaction.copyWith(id: _allocateId());
      _transactions.insert(0, withId);

      // 如果是预交款类型，更新客户预交款余额
      if (transaction.type == TransactionType.prepayment && transaction.customerId != null) {
        final customerIndex = _customers.indexWhere(
          (c) => c.id == transaction.customerId,
        );
        if (customerIndex != -1) {
          _customers[customerIndex] = _customers[customerIndex].copyWith(
            prepaidBalance: _customers[customerIndex].prepaidBalance + transaction.amount,
          );
          await _storage.saveCustomers(_customers);
        }
      }

      await _storage.saveTransactions(_transactions);
      await _loadStatistics();
    } catch (e) {
      _lastError = '添加交易失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      await _storage.saveTransactions(_transactions);
      await _loadStatistics();
    } catch (e) {
      _lastError = '更新交易失败: $e';
      notifyListeners();
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    return List.of(_transactions);
  }

  Future<List<Transaction>> getTransactionsByCustomer(int customerId) async {
    return _transactions.where((t) => t.customerId == customerId).toList();
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) =>
      !t.createdAt.isBefore(start) && !t.createdAt.isAfter(end)
    ).toList();
  }

  // ============ 库存操作 ============

  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      final withId = item.copyWith(id: _allocateId());
      _inventoryItems.add(withId);
      await _storage.saveInventory(_inventoryItems);
      notifyListeners();
    } catch (e) {
      _lastError = '添加库存失败: $e';
      notifyListeners();
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final index = _inventoryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = item;
      }
      await _storage.saveInventory(_inventoryItems);
      notifyListeners();
    } catch (e) {
      _lastError = '更新库存失败: $e';
      notifyListeners();
    }
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
    final data = {
      'customers': _customers.map((c) => c.toMap()).toList(),
      'serviceTypes': _serviceTypes.map((s) => s.toMap()).toList(),
      'copiers': _copiers.map((c) => c.toMap()).toList(),
      'transactions': _transactions.map((t) => t.toMap()).toList(),
      'inventory': _inventoryItems.map((i) => i.toMap()).toList(),
      'exportTime': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
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
