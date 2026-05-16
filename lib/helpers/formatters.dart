import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// ============ 费用类目 ============

String getCategoryName(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.printFee: return '打印费';
    case ExpenseCategory.rentalFee: return '租赁费';
    case ExpenseCategory.accessoryFee: return '配件费';
    case ExpenseCategory.officeSupply: return '办公用品';
    case ExpenseCategory.other: return '其他';
  }
}

Color getCategoryColor(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.printFee: return Colors.blue;
    case ExpenseCategory.rentalFee: return Colors.purple;
    case ExpenseCategory.accessoryFee: return Colors.orange;
    case ExpenseCategory.officeSupply: return Colors.green;
    case ExpenseCategory.other: return Colors.grey;
  }
}

IconData getCategoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.printFee: return Icons.print;
    case ExpenseCategory.rentalFee: return Icons.desktop_windows;
    case ExpenseCategory.accessoryFee: return Icons.build;
    case ExpenseCategory.officeSupply: return Icons.inventory_2;
    case ExpenseCategory.other: return Icons.more_horiz;
  }
}

// ============ 支付方式 ============

String getMethodName(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash: return '现金';
    case PaymentMethod.wechat: return '微信';
    case PaymentMethod.alipay: return '支付宝';
    case PaymentMethod.bankTransfer: return '转账';
  }
}

IconData getMethodIcon(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash: return Icons.money;
    case PaymentMethod.wechat: return Icons.chat;
    case PaymentMethod.alipay: return Icons.payment;
    case PaymentMethod.bankTransfer: return Icons.account_balance;
  }
}

// ============ 货币格式 ============

final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
