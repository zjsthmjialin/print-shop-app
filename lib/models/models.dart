// ============ 费用类目枚举 ============
enum ExpenseCategory {
  printFee,      // 打印费
  rentalFee,     // 租赁费
  accessoryFee,  // 配件费
  officeSupply,  // 办公用品
  other,         // 其他
}

// ============ 服务类型模型 ============
class ServiceType {
  final int? id;
  final String name;
  final ExpenseCategory category;
  final double? unitPrice;
  final bool isActive;
  final DateTime createdAt;

  ServiceType({
    this.id,
    required this.name,
    required this.category,
    this.unitPrice,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'unitPrice': unitPrice,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(
      id: map['id'],
      name: map['name'] ?? '',
      category: (map['category'] ?? 0) is int && (map['category'] as int) < ExpenseCategory.values.length
          ? ExpenseCategory.values[map['category'] as int]
          : ExpenseCategory.other,
      unitPrice: map['unitPrice'] != null ? (map['unitPrice'] as num).toDouble() : null,
      isActive: (map['isActive'] ?? 1) == 1,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  ServiceType copyWith({
    int? id,
    String? name,
    ExpenseCategory? category,
    double? unitPrice,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ServiceType(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ============ 客户模型 ============
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? companyName;
  final double prepaidBalance;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.companyName,
    this.prepaidBalance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'companyName': companyName,
      'prepaidBalance': prepaidBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      companyName: map['companyName'],
      prepaidBalance: (map['prepaidBalance'] ?? 0).toDouble(),
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? companyName,
    double? prepaidBalance,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      prepaidBalance: prepaidBalance ?? this.prepaidBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ============ 复印机模型 ============
class Copier {
  final int? id;
  final String name;
  final double pricePerPage;
  final int? customerId;
  final CopierStatus status;
  final DateTime createdAt;

  Copier({
    this.id,
    required this.name,
    required this.pricePerPage,
    this.customerId,
    this.status = CopierStatus.idle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pricePerPage': pricePerPage,
      'customerId': customerId,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Copier.fromMap(Map<String, dynamic> map) {
    return Copier(
      id: map['id'],
      name: map['name'] ?? '',
      pricePerPage: (map['pricePerPage'] ?? 0).toDouble(),
      customerId: map['customerId'],
      status: (map['status'] ?? 0) is int && (map['status'] as int) < CopierStatus.values.length
          ? CopierStatus.values[map['status'] as int]
          : CopierStatus.idle,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Copier copyWith({
    int? id,
    String? name,
    double? pricePerPage,
    int? customerId,
    CopierStatus? status,
    DateTime? createdAt,
  }) {
    return Copier(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerPage: pricePerPage ?? this.pricePerPage,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum CopierStatus { idle, inUse, maintenance }

// ============ 交易记录模型 ============
class Transaction {
  final int? id;
  final int? serviceTypeId;
  final double amount;
  final String? description;
  final int? customerId;
  final int? copierId;
  final int? pages;
  final PaymentMethod paymentMethod;
  final ExpenseCategory expenseCategory;
  final TransactionType type;
  final bool isPaid;
  final DateTime createdAt;

  Transaction({
    this.id,
    this.serviceTypeId,
    required this.amount,
    this.description,
    this.customerId,
    this.copierId,
    this.pages,
    this.paymentMethod = PaymentMethod.cash,
    required this.expenseCategory,
    this.type = TransactionType.income,
    this.isPaid = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceTypeId': serviceTypeId,
      'amount': amount,
      'description': description,
      'customerId': customerId,
      'copierId': copierId,
      'pages': pages,
      'paymentMethod': paymentMethod.index,
      'expenseCategory': expenseCategory.index,
      'type': type.index,
      'isPaid': isPaid ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      serviceTypeId: map['serviceTypeId'],
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      customerId: map['customerId'],
      copierId: map['copierId'],
      pages: map['pages'],
      paymentMethod: (map['paymentMethod'] ?? 0) is int && (map['paymentMethod'] as int) < PaymentMethod.values.length
          ? PaymentMethod.values[map['paymentMethod'] as int]
          : PaymentMethod.cash,
      expenseCategory: (map['expenseCategory'] ?? 0) is int && (map['expenseCategory'] as int) < ExpenseCategory.values.length
          ? ExpenseCategory.values[map['expenseCategory'] as int]
          : ExpenseCategory.other,
      type: (map['type'] ?? 0) is int && (map['type'] as int) < TransactionType.values.length
          ? TransactionType.values[map['type'] as int]
          : TransactionType.income,
      isPaid: (map['isPaid'] ?? 0) == 1,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Transaction copyWith({
    int? id,
    int? serviceTypeId,
    double? amount,
    String? description,
    int? customerId,
    int? copierId,
    int? pages,
    PaymentMethod? paymentMethod,
    ExpenseCategory? expenseCategory,
    TransactionType? type,
    bool? isPaid,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      customerId: customerId ?? this.customerId,
      copierId: copierId ?? this.copierId,
      pages: pages ?? this.pages,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum TransactionType {
  income,
  expense,
  prepayment,
  settlement,
}

enum PaymentMethod { cash, wechat, alipay, bankTransfer }

// ============ 库存项目模型 ============
class InventoryItem {
  final int? id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double usedStock;
  final double maxStock;
  final double minAlertStock;
  final double purchasePrice;
  final DateTime updatedAt;

  InventoryItem({
    this.id,
    required this.name,
    required this.category,
    this.unit = '包',
    required this.currentStock,
    this.usedStock = 0,
    required this.maxStock,
    this.minAlertStock = 5,
    this.purchasePrice = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get availableStock => currentStock - usedStock;
  bool get isLowStock => availableStock <= minAlertStock;
  double get stockPercentage => maxStock > 0 ? (availableStock / maxStock) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'usedStock': usedStock,
      'maxStock': maxStock,
      'minAlertStock': minAlertStock,
      'purchasePrice': purchasePrice,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      unit: map['unit'] ?? '包',
      currentStock: (map['currentStock'] ?? 0).toDouble(),
      usedStock: (map['usedStock'] ?? 0).toDouble(),
      maxStock: (map['maxStock'] ?? 0).toDouble(),
      minAlertStock: (map['minAlertStock'] ?? 5).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? usedStock,
    double? maxStock,
    double? minAlertStock,
    double? purchasePrice,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      usedStock: usedStock ?? this.usedStock,
      maxStock: maxStock ?? this.maxStock,
      minAlertStock: minAlertStock ?? this.minAlertStock,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============ 安全日期解析 ============
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
