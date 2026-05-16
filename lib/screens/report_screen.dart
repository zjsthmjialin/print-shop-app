import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../helpers/formatters.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedPeriod = 1; // 默认"本月"

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // 本周
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
      case 1: // 本月
        return DateTime(now.year, now.month, 1);
      case 2: // 本年
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  List<Transaction> _filterTransactions(AppProvider provider) {
    final start = _startDate;
    return provider.recentTransactions.where((t) =>
      !t.createdAt.isBefore(start)
    ).toList();
  }

  double _calcIncome(List<Transaction> transactions) {
    return transactions.where((t) => t.type == TransactionType.income && t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calcExpense(List<Transaction> transactions) {
    return transactions.where((t) => t.type == TransactionType.expense && t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  Map<int, double> _calcDailyIncome(List<Transaction> transactions) {
    final daily = <int, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.income && t.amount > 0) {
        final day = t.createdAt.day;
        daily[day] = (daily[day] ?? 0) + t.amount;
      }
    }
    return daily;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据报表')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final filtered = _filterTransactions(provider);
          final income = _calcIncome(filtered);
          final expense = _calcExpense(filtered);
          final net = income - expense;
          final dailyIncome = _calcDailyIncome(filtered);

          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final barGroups = <BarChartGroupData>[];
          double maxBar = 0;
          for (int i = 1; i <= daysInMonth; i++) {
            final val = dailyIncome[i] ?? 0;
            if (val > maxBar) maxBar = val;
            barGroups.add(BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(
                toY: val,
                color: Theme.of(context).primaryColor,
                width: daysInMonth > 20 ? 4 : 8,
              )],
            ));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: ['本周', '本月', '本年'].asMap().entries.map((e) {
                    final isSelected = _selectedPeriod == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = e.key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700])),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(['本周', '本月', '本年'][_selectedPeriod] + '收入', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(currencyFormat.format(income), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('支出: ${currencyFormat.format(expense)}', style: const TextStyle(color: Colors.white70)),
                          const Spacer(),
                          Text('净收: ${currencyFormat.format(net)}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('收入趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: barGroups.isEmpty
                      ? const Center(child: Text('暂无数据'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxBar > 0 ? maxBar * 1.2 : 100,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 20,
                                  getTitlesWidget: (value, meta) {
                                    final day = value.toInt();
                                    if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                                      return Text('$day', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('');
                                    return Text(currencyFormat.format(value), style: const TextStyle(fontSize: 9, color: Colors.grey));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            barGroups: barGroups,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                const Text('收款概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Icon(Icons.description, color: Colors.red[400], size: 32),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(provider.totalOwed), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[400])),
                            const SizedBox(height: 4),
                            Text('欠款总额', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                          children: [
                            Icon(Icons.savings, color: Colors.green[400], size: 32),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(provider.totalPrepaid), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[400])),
                            const SizedBox(height: 4),
                            Text('预缴余额', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
