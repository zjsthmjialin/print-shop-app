import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  String? _documentsPath;

  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      _documentsPath = customPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      _documentsPath = directory.path;
    }
  }

  String get _customersPath => '$_documentsPath/customers.json';
  String get _serviceTypesPath => '$_documentsPath/service_types.json';
  String get _copiersPath => '$_documentsPath/copiers.json';
  String get _transactionsPath => '$_documentsPath/transactions.json';
  String get _inventoryPath => '$_documentsPath/inventory.json';

  // ============ 客户操作 ============

  Future<List<Customer>> loadCustomers() async {
    try {
      final file = File(_customersPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        return data.map((m) => Customer.fromMap(m)).toList();
      }
    } catch (e) {
      print('Error loading customers: $e');
    }
    return [];
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    try {
      final file = File(_customersPath);
      final data = customers.map((c) => c.toMap()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error saving customers: $e');
    }
  }

  // ============ 服务类型操作 ============

  Future<List<ServiceType>> loadServiceTypes() async {
    try {
      final file = File(_serviceTypesPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        return data.map((m) => ServiceType.fromMap(m)).toList();
      }
    } catch (e) {
      print('Error loading service types: $e');
    }
    return [];
  }

  Future<void> saveServiceTypes(List<ServiceType> serviceTypes) async {
    try {
      final file = File(_serviceTypesPath);
      final data = serviceTypes.map((s) => s.toMap()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error saving service types: $e');
    }
  }

  // ============ 复印机操作 ============

  Future<List<Copier>> loadCopiers() async {
    try {
      final file = File(_copiersPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        return data.map((m) => Copier.fromMap(m)).toList();
      }
    } catch (e) {
      print('Error loading copiers: $e');
    }
    return [];
  }

  Future<void> saveCopiers(List<Copier> copiers) async {
    try {
      final file = File(_copiersPath);
      final data = copiers.map((c) => c.toMap()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error saving copiers: $e');
    }
  }

  // ============ 交易记录操作 ============

  Future<List<Transaction>> loadTransactions() async {
    try {
      final file = File(_transactionsPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        return data.map((m) => Transaction.fromMap(m)).toList();
      }
    } catch (e) {
      print('Error loading transactions: $e');
    }
    return [];
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final file = File(_transactionsPath);
      final data = transactions.map((t) => t.toMap()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error saving transactions: $e');
    }
  }

  // ============ 库存操作 ============

  Future<List<InventoryItem>> loadInventory() async {
    try {
      final file = File(_inventoryPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        return data.map((m) => InventoryItem.fromMap(m)).toList();
      }
    } catch (e) {
      print('Error loading inventory: $e');
    }
    return [];
  }

  Future<void> saveInventory(List<InventoryItem> items) async {
    try {
      final file = File(_inventoryPath);
      final data = items.map((i) => i.toMap()).toList();
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('Error saving inventory: $e');
    }
  }

  // ============ 导出数据 ============

  Future<String> exportAllData() async {
    final data = {
      'customers': (await loadCustomers()).map((c) => c.toMap()).toList(),
      'serviceTypes': (await loadServiceTypes()).map((s) => s.toMap()).toList(),
      'copiers': (await loadCopiers()).map((c) => c.toMap()).toList(),
      'transactions': (await loadTransactions()).map((t) => t.toMap()).toList(),
      'inventory': (await loadInventory()).map((i) => i.toMap()).toList(),
      'exportTime': DateTime.now().toIso8601String(),
    };
    return json.encode(data);
  }

  Future<void> importAllData(String jsonData) async {
    try {
      final data = json.decode(jsonData);

      if (data['customers'] != null) {
        final customers = (data['customers'] as List).map((m) => Customer.fromMap(m)).toList();
        await saveCustomers(customers);
      }
      if (data['serviceTypes'] != null) {
        final serviceTypes = (data['serviceTypes'] as List).map((m) => ServiceType.fromMap(m)).toList();
        await saveServiceTypes(serviceTypes);
      }
      if (data['copiers'] != null) {
        final copiers = (data['copiers'] as List).map((m) => Copier.fromMap(m)).toList();
        await saveCopiers(copiers);
      }
      if (data['transactions'] != null) {
        final transactions = (data['transactions'] as List).map((m) => Transaction.fromMap(m)).toList();
        await saveTransactions(transactions);
      }
      if (data['inventory'] != null) {
        final inventory = (data['inventory'] as List).map((m) => InventoryItem.fromMap(m)).toList();
        await saveInventory(inventory);
      }
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }
}
