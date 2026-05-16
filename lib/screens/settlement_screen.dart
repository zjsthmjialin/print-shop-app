import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});
  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  Customer? _selectedCustomer;
  final _amountController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _usePrepaid = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('收款结账')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(currencyFormat.format(provider.totalOwed), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('待收款总额', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.white30),
                  Expanded(
                    child: Column(
                      children: [
                        Text(currencyFormat.format(provider.totalPrepaid), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('预缴余额', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('选择结账客户', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (provider.customers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('暂无客户', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              ...provider.customers.map((customer) => _CustomerSelectItem(
                customer: customer,
                isSelected: _selectedCustomer?.id == customer.id,
                onTap: () => _selectCustomer(customer),
                currencyFormat: currencyFormat,
              )),
            const SizedBox(height: 24),
            const Text('收款方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
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
                        borderRadius: BorderRadius.circular(14),
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
            ),
            const SizedBox(height: 24),
            const Text('收款金额', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (provider.totalPrepaid > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('使用预缴余额抵扣', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('当前预缴: ${currencyFormat.format(provider.totalPrepaid)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _usePrepaid,
                      onChanged: (v) => setState(() => _usePrepaid = v),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCustomer != null && (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) > 0)
                    ? () => _confirmSettlement(context, provider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _selectedCustomer != null
                      ? '确认收款 ${currencyFormat.format(double.tryParse(_amountController.text) ?? 0)}'
                      : '请选择客户',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _selectCustomer(Customer customer) async {
    final provider = context.read<AppProvider>();
    final transactions = await provider.getAllTransactions();
    final customerTransactions = transactions.where((t) => t.customerId == customer.id).toList();
    final total = customerTransactions.fold(0.0, (sum, t) => sum + t.amount);

    setState(() {
      _selectedCustomer = customer;
      _amountController.text = total.toStringAsFixed(2);
      _usePrepaid = false;
    });
  }

  void _confirmSettlement(BuildContext context, AppProvider provider) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || _selectedCustomer == null) return;

    final transaction = Transaction(
      amount: amount,
      customerId: _selectedCustomer!.id,
      paymentMethod: _selectedMethod,
      expenseCategory: ExpenseCategory.other,
      description: '结账收款',
    );

    await provider.addTransaction(transaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usePrepaid ? '收款成功（已抵扣预缴）' : '收款成功'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.wechat: return Icons.chat;
      case PaymentMethod.alipay: return Icons.payment;
      case PaymentMethod.bankTransfer: return Icons.account_balance;
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

class _CustomerSelectItem extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;
  final NumberFormat currencyFormat;

  const _CustomerSelectItem({
    required this.customer,
    required this.isSelected,
    required this.onTap,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(customer.name[0], style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (customer.phone.isNotEmpty)
                    Text(customer.phone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
          ],
        ),
      ),
    );
  }
}
