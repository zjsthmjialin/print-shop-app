import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = '全部';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存管理')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = _selectedCategory == '全部'
              ? provider.inventoryItems
              : provider.inventoryItems.where((i) => i.category == _selectedCategory).toList();
          final lowStockCount = provider.lowStockItems.length;

          return Column(
            children: [
              if (lowStockCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '有 $lowStockCount 项商品库存不足',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: ['全部', '纸张', '耗材', '配件'].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('暂无库存', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddItemDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('添加库存'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _InventoryItemCard(
                            item: item,
                            onTap: () => _showItemDetailDialog(context, item),
                            onAdjust: () => _showAdjustDialog(context, item),
                            onEdit: () => _showEditItemDialog(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final maxController = TextEditingController();
    final minAlertController = TextEditingController(text: '5');
    final purchasePriceController = TextEditingController(text: '0');
    final usedStockController = TextEditingController(text: '0');
    String category = '纸张';
    String unit = '包';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加库存'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称', prefixIcon: Icon(Icons.label))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: '类别', prefixIcon: Icon(Icons.category)),
                        items: ['纸张', '耗材', '配件'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => category = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: unit,
                        decoration: const InputDecoration(labelText: '单位', prefixIcon: Icon(Icons.straighten)),
                        items: ['包', '箱', '个', '盒', '卷', '袋', '套', '台', '支', '瓶', '桶'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: stockController, decoration: const InputDecoration(labelText: '进货数量', prefixIcon: Icon(Icons.add_box)), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: purchasePriceController, decoration: const InputDecoration(labelText: '单价', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: usedStockController, decoration: const InputDecoration(labelText: '已使用数量', prefixIcon: Icon(Icons.check_circle_outline)), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: maxController, decoration: const InputDecoration(labelText: '最大库存', prefixIcon: Icon(Icons.arrow_upward)), keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: minAlertController, decoration: const InputDecoration(labelText: '最低库存提醒', prefixIcon: Icon(Icons.warning)), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                if (stockController.text.isNotEmpty && purchasePriceController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('进货总成本:'),
                        Text('¥${((double.tryParse(stockController.text) ?? 0) * (double.tryParse(purchasePriceController.text) ?? 0)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final item = InventoryItem(
                  name: nameController.text,
                  category: category,
                  unit: unit,
                  currentStock: double.tryParse(stockController.text) ?? 0,
                  usedStock: double.tryParse(usedStockController.text) ?? 0,
                  maxStock: double.tryParse(maxController.text) ?? 100,
                  purchasePrice: double.tryParse(purchasePriceController.text) ?? 0,
                  minAlertStock: double.tryParse(minAlertController.text) ?? 5,
                );
                context.read<AppProvider>().addInventoryItem(item);
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, InventoryItem item) {
    final nameController = TextEditingController(text: item.name);
    final stockController = TextEditingController(text: item.currentStock.toStringAsFixed(0));
    final usedStockController = TextEditingController(text: item.usedStock.toStringAsFixed(0));
    final maxController = TextEditingController(text: item.maxStock.toStringAsFixed(0));
    final purchasePriceController = TextEditingController(text: item.purchasePrice.toStringAsFixed(2));
    final minAlertController = TextEditingController(text: item.minAlertStock.toStringAsFixed(0));
    String category = item.category;
    String unit = item.unit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑库存'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称', prefixIcon: Icon(Icons.label))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: '类别', prefixIcon: Icon(Icons.category)),
                        items: ['纸张', '耗材', '配件'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => category = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: unit,
                        decoration: const InputDecoration(labelText: '单位', prefixIcon: Icon(Icons.straighten)),
                        items: ['包', '箱', '个', '盒', '卷', '袋', '套', '台', '支', '瓶', '桶'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: stockController, decoration: const InputDecoration(labelText: '当前库存', prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: purchasePriceController, decoration: const InputDecoration(labelText: '单价', prefixIcon: Icon(Icons.money), prefixText: '¥'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: usedStockController, decoration: const InputDecoration(labelText: '已使用数量', prefixIcon: Icon(Icons.check_circle_outline)), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: maxController, decoration: const InputDecoration(labelText: '最大库存', prefixIcon: Icon(Icons.arrow_upward)), keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: minAlertController, decoration: const InputDecoration(labelText: '最低库存提醒', prefixIcon: Icon(Icons.warning)), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final updatedItem = item.copyWith(
                  name: nameController.text,
                  category: category,
                  unit: unit,
                  currentStock: double.tryParse(stockController.text) ?? 0,
                  usedStock: double.tryParse(usedStockController.text) ?? 0,
                  maxStock: double.tryParse(maxController.text) ?? 100,
                  purchasePrice: double.tryParse(purchasePriceController.text) ?? 0,
                  minAlertStock: double.tryParse(minAlertController.text) ?? 5,
                  updatedAt: DateTime.now(),
                );
                context.read<AppProvider>().updateInventoryItem(updatedItem);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetailDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: '类别', value: item.category),
            _DetailRow(label: '单位', value: item.unit),
            _DetailRow(label: '当前库存', value: '${item.currentStock.toStringAsFixed(0)} ${item.unit}'),
            _DetailRow(label: '已使用', value: '${item.usedStock.toStringAsFixed(0)} ${item.unit}'),
            _DetailRow(label: '可用库存', value: '${item.availableStock.toStringAsFixed(0)} ${item.unit}'),
            _DetailRow(label: '最大库存', value: '${item.maxStock.toStringAsFixed(0)} ${item.unit}'),
            _DetailRow(label: '最低提醒', value: '${item.minAlertStock.toStringAsFixed(0)} ${item.unit}'),
            _DetailRow(label: '进货价格', value: '¥${item.purchasePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (item.availableStock / item.maxStock).clamp(0, 1),
                backgroundColor: Colors.grey[200],
                color: item.isLowStock ? Colors.orange : Colors.green,
                minHeight: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, InventoryItem item) {
    final amountController = TextEditingController();
    bool isAdd = true;
    bool isUsed = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final amount = double.tryParse(amountController.text) ?? 0;
          final cost = isAdd ? amount * item.purchasePrice : 0.0;

          return AlertDialog(
            title: const Text('调整库存'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text('当前库存', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('${item.currentStock.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text('已使用', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('${item.usedStock.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text('可用库存', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('${item.availableStock.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text('单价', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('¥${item.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { isAdd = true; isUsed = false; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isAdd && !isUsed ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isAdd && !isUsed ? Colors.green : Colors.transparent, width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.add_box, color: isAdd && !isUsed ? Colors.green : Colors.grey),
                                const SizedBox(height: 4),
                                Text('进货', style: TextStyle(color: isAdd && !isUsed ? Colors.green : Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { isAdd = false; isUsed = true; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isUsed ? Colors.orange.withValues(alpha: 0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isUsed ? Colors.orange : Colors.transparent, width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: isUsed ? Colors.orange : Colors.grey),
                                const SizedBox(height: 4),
                                Text('使用', style: TextStyle(color: isUsed ? Colors.orange : Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { isAdd = false; isUsed = false; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isAdd && !isUsed ? Colors.red.withValues(alpha: 0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: !isAdd && !isUsed ? Colors.red : Colors.transparent, width: 2),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.remove_circle, color: !isAdd && !isUsed ? Colors.red : Colors.grey),
                                const SizedBox(height: 4),
                                Text('减少', style: TextStyle(color: !isAdd && !isUsed ? Colors.red : Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '数量',
                      suffixText: item.unit,
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (isAdd && amount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('进货成本:'),
                          Text('¥${cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;

                  double newStock = item.currentStock;
                  double newUsedStock = item.usedStock;

                  if (isUsed) {
                    newUsedStock += amount;
                  } else if (isAdd) {
                    newStock += amount;
                  } else {
                    newStock = (newStock - amount).clamp(0.0, double.maxFinite);
                    newUsedStock = (newUsedStock - amount).clamp(0.0, double.maxFinite);
                  }

                  final updatedItem = item.copyWith(
                    currentStock: newStock,
                    usedStock: newUsedStock,
                    updatedAt: DateTime.now(),
                  );
                  context.read<AppProvider>().updateInventoryItem(updatedItem);
                  Navigator.pop(context);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onAdjust;
  final VoidCallback onEdit;

  const _InventoryItemCard({
    required this.item,
    required this.onTap,
    required this.onAdjust,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: item.isLowStock ? Colors.orange : Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.category == '纸张' ? Colors.blue.withValues(alpha: 0.1)
                        : item.category == '耗材' ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.category, style: TextStyle(
                    color: item.category == '纸张' ? Colors.blue
                        : item.category == '耗材' ? Colors.purple
                        : Colors.orange,
                    fontSize: 11,
                  )),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('编辑')])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.availableStock.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('可用库存', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '¥${item.purchasePrice.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text('单价', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${(item.currentStock * item.purchasePrice).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    Text('合计金额', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('进货: ${item.currentStock.toStringAsFixed(0)} ${item.unit}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const Spacer(),
                if (item.usedStock > 0)
                  Text('已使用: ${item.usedStock.toStringAsFixed(0)} ${item.unit}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (item.availableStock / item.maxStock).clamp(0, 1),
                backgroundColor: Colors.grey[200],
                color: item.isLowStock ? Colors.orange : Colors.green,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdjust,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('调整库存'),
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
