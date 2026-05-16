import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../helpers/formatters.dart';

class CopierScreen extends StatefulWidget {
  const CopierScreen({super.key});
  @override
  State<CopierScreen> createState() => _CopierScreenState();
}

class _CopierScreenState extends State<CopierScreen> {
  double _rentalIncome = 0;

  @override
  void initState() {
    super.initState();
    _loadRentalIncome();
  }

  Future<void> _loadRentalIncome() async {
    final provider = context.read<AppProvider>();
    final transactions = await provider.getAllTransactions();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final income = transactions
        .where((t) => t.expenseCategory == ExpenseCategory.rentalFee &&
            !t.createdAt.isBefore(startOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    if (mounted) {
      setState(() => _rentalIncome = income);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('租赁复印机')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final inUse = provider.copiers.where((c) => c.status == CopierStatus.inUse).toList();
          final idle = provider.copiers.where((c) => c.status == CopierStatus.idle).toList();
          final maintenance = provider.copiers.where((c) => c.status == CopierStatus.maintenance).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('本月租赁收入', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(_rentalIncome), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('复印机数量', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${provider.copiers.length} 台', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (inUse.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('使用中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...inUse.map((copier) {
                    final customer = provider.customers.where((c) => c.id == copier.customerId).firstOrNull;
                    return _CopierCard(
                      copier: copier,
                      customer: customer,
                      currencyFormat: currencyFormat,
                      onAssign: () => _showAssignDialog(context, copier),
                      onUnassign: () => _unassignCopier(context, copier),
                      onRecord: () => _showRecordDialog(context, copier),
                    );
                  }),
                ],
                if (idle.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('闲置中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  ...idle.map((copier) => _CopierCard(
                    copier: copier,
                    customer: null,
                    currencyFormat: currencyFormat,
                    isIdle: true,
                    onAssign: () => _showAssignDialog(context, copier),
                  )),
                ],
                if (maintenance.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('维护中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 12),
                  ...maintenance.map((copier) => _CopierCard(
                    copier: copier,
                    customer: null,
                    currencyFormat: currencyFormat,
                    isMaintenance: true,
                  )),
                ],
                if (provider.copiers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.desktop_windows, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('暂无复印机', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCopierDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCopierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加复印机'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称/型号', prefixIcon: Icon(Icons.desktop_windows))),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: '单价（元/张）', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              context.read<AppProvider>().addCopier(Copier(
                name: nameController.text,
                pricePerPage: double.tryParse(priceController.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, Copier copier) {
    final provider = context.read<AppProvider>();
    final allCustomers = provider.customers;

    if (allCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加客户'), backgroundColor: Colors.orange),
      );
      return;
    }

    Customer? selectedCustomer;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('分配复印机'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('将 "${copier.name}" 分配给：', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              ...allCustomers.map((customer) {
                final isSelected = selectedCustomer?.id == customer.id;
                return GestureDetector(
                  onTap: () => setState(() => selectedCustomer = customer),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: Theme.of(context).primaryColor, radius: 16, child: Text(customer.name[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (customer.companyName != null) Text(customer.companyName!, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: selectedCustomer != null
                  ? () {
                      final updatedCopier = Copier(
                        id: copier.id,
                        name: copier.name,
                        pricePerPage: copier.pricePerPage,
                        customerId: selectedCustomer!.id,
                        status: CopierStatus.inUse,
                        createdAt: copier.createdAt,
                      );
                      provider.updateCopier(updatedCopier);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已分配给 ${selectedCustomer!.name}'), backgroundColor: Colors.green),
                      );
                    }
                  : null,
              child: const Text('确认分配'),
            ),
          ],
        ),
      ),
    );
  }

  void _unassignCopier(BuildContext context, Copier copier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除分配'),
        content: Text('确定要收回 "${copier.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final updatedCopier = Copier(
                id: copier.id,
                name: copier.name,
                pricePerPage: copier.pricePerPage,
                customerId: null,
                status: CopierStatus.idle,
                createdAt: copier.createdAt,
              );
              context.read<AppProvider>().updateCopier(updatedCopier);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已解除分配'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('确认收回'),
          ),
        ],
      ),
    );
  }

  void _showRecordDialog(BuildContext context, Copier copier) {
    final pagesController = TextEditingController();
    final provider = context.read<AppProvider>();
    final customer = provider.customers.where((c) => c.id == copier.customerId).firstOrNull;
    final amount = copier.pricePerPage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录复印'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('复印机: ${copier.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (customer != null) Text('客户: ${customer.name}'),
            const SizedBox(height: 8),
            Text('单价: ¥${amount.toStringAsFixed(2)}/张', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '复印张数',
                prefixIcon: Icon(Icons.copy),
                prefixText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final pages = int.tryParse(pagesController.text) ?? 0;
              if (pages <= 0) return;
              final totalAmount = pages * amount;
              final transaction = Transaction(
                amount: totalAmount,
                copierId: copier.id,
                customerId: copier.customerId,
                pages: pages,
                expenseCategory: ExpenseCategory.rentalFee,
                description: '${copier.name} 复印 ${pages} 张',
                isPaid: true,
              );
              context.read<AppProvider>().addTransaction(transaction);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已记录: ${pages}张 = ¥${totalAmount.toStringAsFixed(2)}'), backgroundColor: Colors.green),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

class _CopierCard extends StatelessWidget {
  final Copier copier;
  final Customer? customer;
  final NumberFormat currencyFormat;
  final bool isIdle;
  final bool isMaintenance;
  final VoidCallback? onAssign;
  final VoidCallback? onUnassign;
  final VoidCallback? onRecord;

  const _CopierCard({
    required this.copier,
    this.customer,
    required this.currencyFormat,
    this.isIdle = false,
    this.isMaintenance = false,
    this.onAssign,
    this.onUnassign,
    this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isIdle ? Colors.grey[200] : isMaintenance ? Colors.orange[50] : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.desktop_windows, color: isIdle ? Colors.grey : isMaintenance ? Colors.orange : Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(currencyFormat.format(copier.pricePerPage) + '/张', style: TextStyle(color: Colors.green[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isIdle ? Colors.grey[200] : isMaintenance ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(isIdle ? '闲置' : isMaintenance ? '维护中' : '使用中', style: TextStyle(color: isIdle ? Colors.grey : isMaintenance ? Colors.orange : Colors.green, fontSize: 12)),
              ),
            ],
          ),
          if (customer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Text('租给', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(customer!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ],
          if (!isIdle && !isMaintenance && onRecord != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecord,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('记录复印'),
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUnassign,
                    icon: const Icon(Icons.assignment_return, size: 18),
                    label: const Text('收回'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
          if (isIdle && onAssign != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.person_add),
                label: const Text('分配给客户'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
