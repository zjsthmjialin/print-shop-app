import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'record_screen.dart';
import 'customer_screen.dart';
import 'inventory_screen.dart';
import 'report_screen.dart';
import 'copier_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const RecordScreen(),
    const CustomerScreen(),
    const InventoryScreen(),
    const ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: '记账'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '客户'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: '库存'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '报表'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('欢迎回来', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      const Text('打印店记账', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(
                        title: '今日收入',
                        value: currencyFormat.format(provider.todayIncome),
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        icon: Icons.trending_up,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        title: '本月净收',
                        value: currencyFormat.format(provider.monthIncome - provider.monthExpense.abs()),
                        icon: Icons.account_balance_wallet,
                      )),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _PaymentCard(
                            label: '未结款',
                            value: currencyFormat.format(provider.totalUnpaid),
                            icon: Icons.pending_actions,
                            color: Colors.red,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerScreen())),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _PaymentCard(
                            label: '已结款',
                            value: currencyFormat.format(provider.totalPaid),
                            icon: Icons.check_circle,
                            color: Colors.blue,
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _PaymentCard(
                            label: '预交款',
                            value: currencyFormat.format(provider.totalPrepaid),
                            icon: Icons.savings,
                            color: Colors.green,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerScreen())),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _PaymentCard(
                            label: '本月净收',
                            value: currencyFormat.format(provider.monthIncome - provider.monthExpense.abs()),
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('快捷记账', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CopierScreen())),
                        child: const Text('复印机管理'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildListDelegate([
                    _QuickActionButton(
                      icon: Icons.print,
                      label: '打印',
                      color: const Color(0xFFE3F2FD),
                      onTap: () => _quickRecord(context, ExpenseCategory.printFee),
                    ),
                    _QuickActionButton(
                      icon: Icons.desktop_windows,
                      label: '租赁',
                      color: const Color(0xFFE8EAF6),
                      onTap: () => _quickRecord(context, ExpenseCategory.rentalFee),
                    ),
                    _QuickActionButton(
                      icon: Icons.build,
                      label: '配件',
                      color: const Color(0xFFFFF3E0),
                      onTap: () => _quickRecord(context, ExpenseCategory.accessoryFee),
                    ),
                    _QuickActionButton(
                      icon: Icons.inventory_2,
                      label: '办公',
                      color: const Color(0xFFE8F5E9),
                      onTap: () => _quickRecord(context, ExpenseCategory.officeSupply),
                    ),
                    _QuickActionButton(
                      icon: Icons.copy,
                      label: '复印机',
                      color: const Color(0xFFF3E5F5),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CopierScreen())),
                    ),
                    _QuickActionButton(
                      icon: Icons.settings,
                      label: '设置',
                      color: const Color(0xFFE0F7FA),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CopierScreen())),
                    ),
                    _QuickActionButton(
                      icon: Icons.design_services,
                      label: '设计',
                      color: const Color(0xFFFCE4EC),
                      onTap: () => _quickRecord(context, ExpenseCategory.other),
                    ),
                    _QuickActionButton(
                      icon: Icons.desktop_windows,
                      label: '租赁复印',
                      color: const Color(0xFFE8EAF6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CopierScreen())),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('最近记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => _showAllTransactions(context, provider),
                        child: const Text('查看全部'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= provider.recentTransactions.length) return null;
                      return _TransactionItem(transaction: provider.recentTransactions[index]);
                    },
                    childCount: provider.recentTransactions.length > 5 ? 5 : provider.recentTransactions.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
    );
  }

  void _quickRecord(BuildContext context, ExpenseCategory category) {
    final provider = context.read<AppProvider>();
    final serviceTypes = provider.getServiceTypesByCategory(category);
    final amountController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;
    ServiceType? selectedType;

    if (serviceTypes.isNotEmpty) {
      selectedType = serviceTypes.first;
      if (selectedType.unitPrice != null) {
        amountController.text = selectedType.unitPrice.toString();
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_getCategoryName(category)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (serviceTypes.isNotEmpty) ...[
                DropdownButtonFormField<ServiceType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '服务类型', prefixIcon: Icon(Icons.label)),
                  items: serviceTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text('${t.name}${t.unitPrice != null ? ' (¥${t.unitPrice!.toStringAsFixed(2)})' : ''}'),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    selectedType = v;
                    if (v?.unitPrice != null) {
                      amountController.text = v!.unitPrice.toString();
                    }
                  }),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixIcon: Icon(Icons.money),
                  prefixText: '¥',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('收款方式', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((method) {
                  final isSelected = selectedMethod == method;
                  return ChoiceChip(
                    label: Text(_getMethodName(method)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => selectedMethod = method),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效金额'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final transaction = Transaction(
                  serviceTypeId: selectedType?.id,
                  amount: amount,
                  paymentMethod: selectedMethod,
                  expenseCategory: category,
                  description: selectedType?.name ?? _getCategoryName(category),
                );
                provider.addTransaction(transaction);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('已添加: ${selectedType?.name ?? _getCategoryName(category)} ¥$amount'), backgroundColor: Colors.green),
                );
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllTransactions(BuildContext context, AppProvider provider) async {
    final transactions = await provider.getAllTransactions();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('全部记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('暂无记录'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) => _TransactionItem(transaction: transactions[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return '现金';
      case PaymentMethod.wechat: return '微信';
      case PaymentMethod.alipay: return '支付宝';
      case PaymentMethod.bankTransfer: return '转账';
    }
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
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final Gradient? gradient;
  final IconData icon;
  const _StatCard({required this.title, required this.value, this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _PaymentCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _getCategoryColor(transaction.expenseCategory).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_getCategoryIcon(transaction.expenseCategory), color: _getCategoryColor(transaction.expenseCategory)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description ?? _getCategoryName(transaction.expenseCategory), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(DateFormat('MM-dd HH:mm').format(transaction.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                if (transaction.pages != null && transaction.pages! > 0)
                  Text('${transaction.pages}张', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isIncome ? '+' : ''}${currencyFormat.format(transaction.amount)}', style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                child: Text(_getMethodName(transaction.paymentMethod), style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ),
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

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return '现金';
      case PaymentMethod.wechat: return '微信';
      case PaymentMethod.alipay: return '支付宝';
      case PaymentMethod.bankTransfer: return '转账';
    }
  }
}
