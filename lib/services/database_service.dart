import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  final List<Map<String, dynamic>> _customers = [];
  final List<Map<String, dynamic>> _copiers = [];
  final List<Map<String, dynamic>> _transactions = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _serviceTypes = [];

  int _customerId = 1;
  int _copierId = 1;
  int _transactionId = 1;
  int _inventoryId = 1;
  int _serviceTypeId = 1;

  // ============ 服务类型操作 ============

  Future<int> insertServiceType(ServiceType serviceType) async {
    final map = serviceType.toMap()..['id'] = _serviceTypeId++;
    _serviceTypes.add(map);
    return map['id'] as int;
  }

  Future<List<ServiceType>> getAllServiceTypes() async {
    return _serviceTypes.map((m) => ServiceType.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<ServiceType>> getServiceTypesByCategory(ExpenseCategory category) async {
    return _serviceTypes
        .where((m) => m['category'] == category.index && (m['isActive'] ?? 1) == 1)
        .map((m) => ServiceType.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<ServiceType>> getActiveServiceTypes() async {
    return _serviceTypes
        .where((m) => (m['isActive'] ?? 1) == 1)
        .map((m) => ServiceType.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<ServiceType?> getServiceType(int id) async {
    final found = _serviceTypes.where((m) => m['id'] == id).firstOrNull;
    return found != null ? ServiceType.fromMap(Map<String, dynamic>.from(found)) : null;
  }

  Future<int> updateServiceType(ServiceType serviceType) async {
    final index = _serviceTypes.indexWhere((m) => m['id'] == serviceType.id);
    if (index != -1) {
      _serviceTypes[index] = serviceType.toMap();
    }
    return 1;
  }

  Future<int> deleteServiceType(int id) async {
    _serviceTypes.removeWhere((m) => m['id'] == id);
    return 1;
  }

  // ============ 客户操作 ============

  Future<int> insertCustomer(Customer customer) async {
    final map = customer.toMap()..['id'] = _customerId++;
    _customers.add(map);
    return map['id'] as int;
  }

  Future<List<Customer>> getAllCustomers() async {
    return _customers.map((m) => Customer.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final found = _customers.where((m) => m['id'] == id).firstOrNull;
    return found != null ? Customer.fromMap(Map<String, dynamic>.from(found)) : null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final index = _customers.indexWhere((m) => m['id'] == customer.id);
    if (index != -1) {
      _customers[index] = customer.toMap();
    }
    return 1;
  }

  Future<int> deleteCustomer(int id) async {
    _customers.removeWhere((m) => m['id'] == id);
    return 1;
  }

  Future<void> updateCustomerPrepaid(int customerId, double amount) async {
    final index = _customers.indexWhere((m) => m['id'] == customerId);
    if (index != -1) {
      final current = (_customers[index]['prepaidBalance'] ?? 0.0) as double;
      _customers[index]['prepaidBalance'] = current + amount;
    }
  }

  // ============ 复印机操作 ============

  Future<int> insertCopier(Copier copier) async {
    final map = copier.toMap()..['id'] = _copierId++;
    _copiers.add(map);
    return map['id'] as int;
  }

  Future<List<Copier>> getAllCopiers() async {
    return _copiers.map((m) => Copier.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<Copier>> getCopiersByCustomer(int customerId) async {
    return _copiers
        .where((m) => m['customerId'] == customerId)
        .map((m) => Copier.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> updateCopier(Copier copier) async {
    final index = _copiers.indexWhere((m) => m['id'] == copier.id);
    if (index != -1) {
      _copiers[index] = copier.toMap();
    }
    return 1;
  }

  // ============ 交易记录操作 ============

  Future<int> insertTransaction(Transaction transaction) async {
    final map = transaction.toMap()..['id'] = _transactionId++;
    _transactions.add(map);

    // 如果是预交款，更新客户预交款余额
    if (transaction.type == TransactionType.prepayment && transaction.customerId != null) {
      await updateCustomerPrepaid(transaction.customerId!, transaction.amount);
    }

    return map['id'] as int;
  }

  Future<List<Transaction>> getAllTransactions() async {
    final sorted = List<Map<String, dynamic>>.from(_transactions);
    sorted.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return sorted.map((m) => Transaction.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final sorted = List<Map<String, dynamic>>.from(_transactions);
    sorted.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return sorted.take(limit).map((m) => Transaction.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<Transaction>> getTransactionsByCustomer(int customerId) async {
    final filtered = _transactions.where((m) => m['customerId'] == customerId).toList();
    filtered.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return filtered.map((m) => Transaction.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((m) => m['id'] == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction.toMap();
    }
    return 1;
  }

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final filtered = _transactions.where((m) {
      final createdAt = DateTime.parse(m['createdAt']);
      return createdAt.isAfter(start) && createdAt.isBefore(end);
    }).toList();
    filtered.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return filtered.map((m) => Transaction.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  // ============ 统计操作 ============

  Future<double> getTodayIncome() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    double total = 0;
    for (final m in _transactions) {
      final type = m['type'] as int;
      final amount = (m['amount'] as double?) ?? 0.0;
      final createdAt = DateTime.parse(m['createdAt'] as String);
      if (type == TransactionType.income.index && amount > 0 && createdAt.isAfter(startOfDay)) {
        total += amount;
      }
    }
    return total;
  }

  Future<double> getMonthIncome() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;
    for (final m in _transactions) {
      final type = m['type'] as int;
      final amount = (m['amount'] as double?) ?? 0.0;
      final createdAt = DateTime.parse(m['createdAt'] as String);
      if (type == TransactionType.income.index && amount > 0 && createdAt.isAfter(startOfMonth)) {
        total += amount;
      }
    }
    return total;
  }

  Future<double> getMonthExpense() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;
    for (final m in _transactions) {
      final type = m['type'] as int;
      final amount = (m['amount'] as double?) ?? 0.0;
      final createdAt = DateTime.parse(m['createdAt'] as String);
      if (type == TransactionType.expense.index && amount < 0 && createdAt.isAfter(startOfMonth)) {
        total += amount.abs();
      }
    }
    return total;
  }

  // 客户未结款金额
  Future<double> getCustomerUnpaidAmount(int customerId) async {
    double total = 0;
    for (final m in _transactions) {
      if (m['customerId'] == customerId) {
        final isPaid = (m['isPaid'] ?? 1) == 1;
        final type = m['type'] as int;
        final amount = (m['amount'] as double?) ?? 0.0;
        // 只有收入类型且未结款的才计入未结款
        if (type == TransactionType.income.index && !isPaid && amount > 0) {
          total += amount;
        }
      }
    }
    return total;
  }

  // 客户已结款金额
  Future<double> getCustomerPaidAmount(int customerId) async {
    double total = 0;
    for (final m in _transactions) {
      if (m['customerId'] == customerId) {
        final isPaid = (m['isPaid'] ?? 1) == 1;
        final type = m['type'] as int;
        final amount = (m['amount'] as double?) ?? 0.0;
        // 收入类型已结款的 + 结款记录
        if (type == TransactionType.income.index && isPaid && amount > 0) {
          total += amount;
        } else if (type == TransactionType.settlement.index) {
          total += amount.abs();
        }
      }
    }
    return total;
  }

  // 所有客户未结款汇总
  Future<double> getTotalUnpaid() async {
    double total = 0;
    for (final m in _transactions) {
      final isPaid = (m['isPaid'] ?? 1) == 1;
      final type = m['type'] as int;
      final amount = (m['amount'] as double?) ?? 0.0;
      if (m['customerId'] != null && type == TransactionType.income.index && !isPaid && amount > 0) {
        total += amount;
      }
    }
    return total;
  }

  // 所有客户已结款汇总
  Future<double> getTotalPaid() async {
    double total = 0;
    for (final m in _transactions) {
      final type = m['type'] as int;
      final amount = (m['amount'] as double?) ?? 0.0;
      if (m['customerId'] != null) {
        if (type == TransactionType.income.index && amount > 0) {
          total += amount;
        }
      }
    }
    // 减去未结款
    total -= await getTotalUnpaid();
    return total > 0 ? total : 0;
  }

  // 所有客户预交款汇总
  Future<double> getTotalPrepaid() async {
    double total = 0;
    for (final m in _customers) {
      total += (m['prepaidBalance'] ?? 0) as double;
    }
    return total > 0 ? total : 0;
  }

  Future<double> getTotalOwed() async {
    return await getTotalUnpaid();
  }

  // ============ 库存操作 ============

  Future<int> insertInventoryItem(InventoryItem item) async {
    final map = item.toMap()..['id'] = _inventoryId++;
    _inventory.add(map);
    return map['id'] as int;
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    return _inventory.map((m) => InventoryItem.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<InventoryItem>> getInventoryByCategory(String category) async {
    return _inventory
        .where((m) => m['category'] == category)
        .map((m) => InventoryItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final index = _inventory.indexWhere((m) => m['id'] == item.id);
    if (index != -1) {
      _inventory[index] = item.toMap();
    }
    return 1;
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    return _inventory
        .where((m) {
          final item = InventoryItem.fromMap(m);
          return item.isLowStock;
        })
        .map((m) => InventoryItem.fromMap(m))
        .toList();
  }

  // ============ 统计操作 ============

  Future<Map<ExpenseCategory, double>> getCategorySummary() async {
    final summary = <ExpenseCategory, double>{};
    for (final category in ExpenseCategory.values) {
      double total = 0;
      for (final m in _transactions) {
        if (m['expenseCategory'] == category.index) {
          final amount = (m['amount'] as double?) ?? 0.0;
          if (amount > 0) total += amount;
        }
      }
      summary[category] = total;
    }
    return summary;
  }

  // ============ 初始化默认服务类型 ============

  Future<void> initDefaultServiceTypes() async {
    if (_serviceTypes.isNotEmpty) return;

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
      await insertServiceType(service);
    }
  }
}
