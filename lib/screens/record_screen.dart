import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../helpers/formatters.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  ServiceType? _selectedServiceType;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pagesController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  Customer? _selectedCustomer;
  ExpenseCategory _selectedCategory = ExpenseCategory.printFee;

  void _updateAmount() {
    if (_selectedServiceType?.unitPrice != null && _pagesController.text.isNotEmpty) {
      final pages = int.tryParse(_pagesController.text) ?? 0;
      final unitPrice = _selectedServiceType!.unitPrice!;
      final amount = pages * unitPrice;
      _amountController.text = amount.toStringAsFixed(2);
    }
  }

  String _calculateAmount() {
    if (_selectedServiceType?.unitPrice != null && _pagesController.text.isNotEmpty) {
      final pages = int.tryParse(_pagesController.text) ?? 0;
      final unitPrice = _selectedServiceType!.unitPrice!;
      final amount = pages * unitPrice;
      return amount.toStringAsFixed(2);
    }
    return '0.00';
  }

  bool _canSave() {
    if (_selectedServiceType == null) return false;
    if (_amountController.text.isEmpty) return false;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return false;
    // 如果服务类型有单价，则必须填写数量
    if (_selectedServiceType!.unitPrice != null && _pagesController.text.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showServiceTypeManager(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择费用类目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                const SizedBox(height: 24),
                const Text('选择服务类型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildServiceTypeSelector(provider),
                const SizedBox(height: 24),
                const Text('选择客户（可选）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildCustomerSelector(provider),
                const SizedBox(height: 24),
                const Text('金额', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.money),
                    prefixText: '¥',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    hintText: _selectedServiceType?.unitPrice != null
                        ? '参考价: ¥${_selectedServiceType!.unitPrice!.toStringAsFixed(2)}/张'
                        : null,
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '数量',
                    prefixIcon: const Icon(Icons.copy),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixText: _selectedServiceType?.unitPrice != null ? '× ¥${_selectedServiceType!.unitPrice!.toStringAsFixed(2)} = ¥${_calculateAmount()}' : null,
                  ),
                  onChanged: (_) {
                    _updateAmount();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '备注',
                    prefixIcon: const Icon(Icons.note),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('收款方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildPaymentMethodSelector(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave() ? () => _saveTransaction(context, provider) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('保存记录', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedCategory = cat;
            _selectedServiceType = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _getCategoryColor(cat).withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? _getCategoryColor(cat) : Colors.transparent, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(cat), size: 18, color: isSelected ? _getCategoryColor(cat) : Colors.grey[700]),
                const SizedBox(width: 6),
                Text(_getCategoryName(cat), style: TextStyle(color: isSelected ? _getCategoryColor(cat) : Colors.grey[700])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceTypeSelector(AppProvider provider) {
    final serviceTypes = provider.getServiceTypesByCategory(_selectedCategory);

    if (serviceTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('该类目下暂无服务类型', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showAddServiceTypeDialog(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('添加服务类型'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: serviceTypes.map((type) {
            final isSelected = _selectedServiceType?.id == type.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedServiceType = type;
                  _updateAmount();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                ),
                child: Column(
                  children: [
                    Text(type.name, style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                    if (type.unitPrice != null)
                      Text('¥${type.unitPrice!.toStringAsFixed(2)}', style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[500],
                      )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showAddServiceTypeDialog(context, provider),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加服务类型'),
        ),
      ],
    );
  }

  Widget _buildCustomerSelector(AppProvider provider) {
    return GestureDetector(
      onTap: () => _showCustomerPicker(provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_selectedCustomer != null ? Icons.person : Icons.person_outline, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCustomer?.name ?? '选择客户',
                style: TextStyle(
                  color: _selectedCustomer != null ? Colors.black : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            if (_selectedCustomer != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedCustomer = null),
              )
            else
              const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: PaymentMethod.values.map((method) {
        final isSelected = _selectedMethod == method;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = method),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
              ),
              child: Column(
                children: [
                  Icon(_getMethodIcon(method), color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                  const SizedBox(height: 4),
                  Text(_getMethodName(method), style: TextStyle(fontSize: 12, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCustomerPicker(AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('选择客户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: provider.customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('暂无客户', style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddCustomerDialog(provider);
                          },
                          child: const Text('添加客户'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = provider.customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(customer.name[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(customer.phone),
                        onTap: () {
                          setState(() => _selectedCustomer = customer);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(AppProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加客户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: '电话', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final customer = Customer(name: nameController.text, phone: phoneController.text);
              provider.addCustomer(customer);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceTypeDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加服务类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '服务名称', prefixIcon: Icon(Icons.label))),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: '单价（元/张，选填）', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final serviceType = ServiceType(
                name: nameController.text,
                category: _selectedCategory,
                unitPrice: double.tryParse(priceController.text),
              );
              provider.addServiceType(serviceType);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showServiceTypeManager(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceTypeManagerScreen()),
    );
  }

  void _saveTransaction(BuildContext context, AppProvider provider) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _selectedServiceType == null) return;

    final transaction = Transaction(
      serviceTypeId: _selectedServiceType!.id,
      amount: amount,
      description: _descriptionController.text.isEmpty ? _selectedServiceType!.name : _descriptionController.text,
      customerId: _selectedCustomer?.id,
      pages: int.tryParse(_pagesController.text),
      paymentMethod: _selectedMethod,
      expenseCategory: _selectedCategory,
      isPaid: _selectedCustomer == null, // 无客户则默认已结款
    );

    await provider.addTransaction(transaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('记录已保存'), backgroundColor: Colors.green));
      setState(() {
        _selectedServiceType = null;
        _amountController.clear();
        _descriptionController.clear();
        _pagesController.clear();
        _selectedCustomer = null;
      });
    }
  }

  String _getCategoryName(ExpenseCategory category) => getCategoryName(category);

  Color _getCategoryColor(ExpenseCategory category) => getCategoryColor(category);

  IconData _getCategoryIcon(ExpenseCategory category) => getCategoryIcon(category);

  IconData _getMethodIcon(PaymentMethod method) => getMethodIcon(method);

  String _getMethodName(PaymentMethod method) => getMethodName(method);
}

// ============ 服务类型管理页面 ============
class ServiceTypeManagerScreen extends StatelessWidget {
  const ServiceTypeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务类型管理')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final groupedTypes = <ExpenseCategory, List<ServiceType>>{};
          for (final category in ExpenseCategory.values) {
            final types = provider.serviceTypes.where((s) => s.category == category).toList();
            if (types.isNotEmpty) {
              groupedTypes[category] = types;
            }
          }

          if (groupedTypes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无服务类型', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedTypes.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(entry.key), size: 20, color: _getCategoryColor(entry.key)),
                      const SizedBox(width: 8),
                      Text(_getCategoryName(entry.key), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map((type) => _ServiceTypeItem(serviceType: type)),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.printFee;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加服务类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '服务名称', prefixIcon: Icon(Icons.label))),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: '所属类目', prefixIcon: Icon(Icons.category)),
                items: ExpenseCategory.values.map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(children: [Icon(_getCategoryIcon(c), size: 18), const SizedBox(width: 8), Text(_getCategoryName(c))]),
                )).toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: '单价（元/张，选填）', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final serviceType = ServiceType(
                  name: nameController.text,
                  category: selectedCategory,
                  unitPrice: double.tryParse(priceController.text),
                );
                context.read<AppProvider>().addServiceType(serviceType);
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.printFee: return '打印费';
      case ExpenseCategory.rentalFee: return '租赁费';
      case ExpenseCategory.accessoryFee: return '配件费';
      case ExpenseCategory.officeSupply: return '办公用品';
      case ExpenseCategory.other: return '其他';
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.printFee: return Colors.blue;
      case ExpenseCategory.rentalFee: return Colors.purple;
      case ExpenseCategory.accessoryFee: return Colors.orange;
      case ExpenseCategory.officeSupply: return Colors.green;
      case ExpenseCategory.other: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.printFee: return Icons.print;
      case ExpenseCategory.rentalFee: return Icons.desktop_windows;
      case ExpenseCategory.accessoryFee: return Icons.build;
      case ExpenseCategory.officeSupply: return Icons.inventory_2;
      case ExpenseCategory.other: return Icons.more_horiz;
    }
  }
}

class _ServiceTypeItem extends StatelessWidget {
  final ServiceType serviceType;

  const _ServiceTypeItem({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceType.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (serviceType.unitPrice != null)
                  Text('¥${serviceType.unitPrice!.toStringAsFixed(2)}/张', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: serviceType.isActive,
            onChanged: (v) {
              context.read<AppProvider>().updateServiceType(serviceType.copyWith(isActive: v));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context);
              } else if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('编辑')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: serviceType.name);
    final priceController = TextEditingController(text: serviceType.unitPrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑服务类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '服务名称', prefixIcon: Icon(Icons.label))),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: '单价（元/张）', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              context.read<AppProvider>().updateServiceType(serviceType.copyWith(
                name: nameController.text,
                unitPrice: double.tryParse(priceController.text),
              ));
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务类型'),
        content: Text('确定要删除 "${serviceType.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().deleteServiceType(serviceType.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
