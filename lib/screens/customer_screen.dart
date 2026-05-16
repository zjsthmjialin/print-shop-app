import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('客户管理')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return provider.customers.isEmpty
              ? _buildEmptyState(provider)
              : _buildCustomerList(provider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无客户', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddCustomerDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('添加客户'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.customers.length,
      itemBuilder: (context, index) {
        final customer = provider.customers[index];
        return FutureBuilder<_CustomerStats>(
          future: _getCustomerStats(customer.id!, provider),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? _CustomerStats(0, 0, 0);
            return _CustomerCard(
              customer: customer,
              stats: stats,
              onTap: () => _showCustomerDetail(context, customer),
              onDelete: () => _confirmDelete(context, customer, provider),
              onAddPrepaid: () => _showAddPrepaidDialog(context, customer, provider),
            );
          },
        );
      },
    );
  }

  Future<_CustomerStats> _getCustomerStats(int customerId, AppProvider provider) async {
    final unpaid = await provider.getCustomerUnpaidAmount(customerId);
    final paid = await provider.getCustomerPaidAmount(customerId);
    return _CustomerStats(unpaid, paid, 0);
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加客户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: '电话', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: companyController, decoration: const InputDecoration(labelText: '公司名称（可选）', prefixIcon: Icon(Icons.business))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              context.read<AppProvider>().addCustomer(Customer(
                name: nameController.text,
                phone: phoneController.text,
                companyName: companyController.text.isEmpty ? null : companyController.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer)),
    );
  }

  void _showAddPrepaidDialog(BuildContext context, Customer customer, AppProvider provider) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加预交款 - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前预交款余额: ¥${customer.prepaidBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '预交金额',
                prefixIcon: Icon(Icons.money),
                prefixText: '¥',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              provider.addCustomerPrepaid(customer.id!, amount);
              // 同时记录预交款交易
              final transaction = Transaction(
                amount: amount,
                customerId: customer.id,
                expenseCategory: ExpenseCategory.other,
                type: TransactionType.prepayment,
                description: '预交款',
              );
              provider.addTransaction(transaction);
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除客户'),
        content: Text('确定要删除客户 "${customer.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              provider.deleteCustomer(customer.id!);
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

class _CustomerStats {
  final double unpaid;
  final double paid;
  final double prepaid;
  _CustomerStats(this.unpaid, this.paid, this.prepaid);
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final _CustomerStats stats;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddPrepaid;

  const _CustomerCard({
    required this.customer,
    required this.stats,
    required this.onTap,
    required this.onDelete,
    required this.onAddPrepaid,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(customer.name[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(customer.phone.isEmpty ? '无电话' : customer.phone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        else if (value == 'prepaid') onAddPrepaid();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'prepaid', child: Row(children: [Icon(Icons.add_card, size: 20), SizedBox(width: 8), Text('添加预交款')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: '未结款',
                        value: currencyFormat.format(stats.unpaid),
                        color: Colors.red,
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Expanded(
                      child: _StatItem(
                        label: '已结款',
                        value: currencyFormat.format(stats.paid),
                        color: Colors.blue,
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Expanded(
                      child: _StatItem(
                        label: '预交款',
                        value: currencyFormat.format(customer.prepaidBalance),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// ============ 客户详情页面 ============
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Transaction> _transactions = [];
  double _unpaid = 0;
  double _paid = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<AppProvider>();
    final transactions = await provider.getTransactionsByCustomer(widget.customer.id!);
    final unpaid = await provider.getCustomerUnpaidAmount(widget.customer.id!);
    final paid = await provider.getCustomerPaidAmount(widget.customer.id!);

    if (mounted) {
      setState(() {
        _transactions = transactions;
        _unpaid = unpaid;
        _paid = paid;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(icon: const Icon(Icons.add_card), onPressed: () => _showAddPrepaidDialog()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 客户信息卡片
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(widget.customer.name[0], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        ),
                        const SizedBox(height: 12),
                        Text(widget.customer.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        if (widget.customer.phone.isNotEmpty) Text(widget.customer.phone, style: const TextStyle(color: Colors.white70)),
                        if (widget.customer.companyName != null) Text(widget.customer.companyName!, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 账务统计卡片
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.pending_actions, color: Colors.red, size: 32),
                                  const SizedBox(height: 8),
                                  Text(currencyFormat.format(_unpaid), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                  const Text('未结款', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 60, color: Colors.grey[300]),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.blue, size: 32),
                                  const SizedBox(height: 8),
                                  Text(currencyFormat.format(_paid), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  const Text('已结款', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 60, color: Colors.grey[300]),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.savings, color: Colors.green, size: 32),
                                  const SizedBox(height: 8),
                                  Text(currencyFormat.format(widget.customer.prepaidBalance), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                  const Text('预交款', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 结款按钮
                  if (_unpaid > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSettlementDialog(),
                        icon: const Icon(Icons.check_circle),
                        label: Text('结款 ¥${_unpaid.toStringAsFixed(2)}'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 交易记录
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('交易记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_transactions.length} 条', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Column(children: [Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]), const SizedBox(height: 12), Text('暂无交易记录', style: TextStyle(color: Colors.grey[500]))])),
                    )
                  else
                    ..._transactions.map((t) => _TransactionItem(transaction: t, currencyFormat: currencyFormat)),
                ],
              ),
            ),
    );
  }

  void _showAddPrepaidDialog() {
    final amountController = TextEditingController();
    final provider = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加预交款'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前预交款余额: ¥${widget.customer.prepaidBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '预交金额', prefixIcon: Icon(Icons.money), prefixText: '¥'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              provider.addCustomerPrepaid(widget.customer.id!, amount);
              final transaction = Transaction(
                amount: amount,
                customerId: widget.customer.id,
                expenseCategory: ExpenseCategory.other,
                type: TransactionType.prepayment,
                description: '预交款',
              );
              provider.addTransaction(transaction);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showSettlementDialog() {
    final amountController = TextEditingController(text: _unpaid.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结款'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('未结款金额: ¥${_unpaid.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '结款金额', prefixIcon: Icon(Icons.money), prefixText: '¥'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              // 将该客户所有未结款标记为已结款
              _settleAllUnpaid(amount);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('确认结款'),
          ),
        ],
      ),
    );
  }

  Future<void> _settleAllUnpaid(double settlementAmount) async {
    final provider = context.read<AppProvider>();

    // 将未结款交易标记为已结款
    for (final t in _transactions) {
      if (t.type == TransactionType.income && !t.isPaid) {
        await provider.updateTransaction(t.copyWith(isPaid: true));
      }
    }

    // 记录结款交易
    final transaction = Transaction(
      amount: settlementAmount,
      customerId: widget.customer.id,
      expenseCategory: ExpenseCategory.other,
      type: TransactionType.settlement,
      description: '结款',
    );
    await provider.addTransaction(transaction);

    // 如果有预交款，先用预交款抵扣
    if (widget.customer.prepaidBalance > 0) {
      await provider.addCustomerPrepaid(widget.customer.id!, -settlementAmount.clamp(0.0, widget.customer.prepaidBalance));
    }

    _loadData();
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;

  const _TransactionItem({required this.transaction, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isPaid = transaction.isPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isIncome && !isPaid ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.expenseCategory).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getCategoryIcon(transaction.expenseCategory), size: 20, color: _getCategoryColor(transaction.expenseCategory)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(transaction.description ?? _getCategoryName(transaction.expenseCategory), style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (transaction.type == TransactionType.prepayment)
                      Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('预交款', style: TextStyle(color: Colors.green, fontSize: 10))),
                    if (transaction.type == TransactionType.settlement)
                      Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('结款', style: TextStyle(color: Colors.blue, fontSize: 10))),
                    if (isIncome && !isPaid)
                      Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: const Text('未结', style: TextStyle(color: Colors.red, fontSize: 10))),
                  ],
                ),
                Text(DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currencyFormat.format(transaction.amount), style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.red : Colors.green)),
              if (transaction.pages != null && transaction.pages! > 0)
                Text('${transaction.pages}张', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ],
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
