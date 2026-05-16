import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    return Scaffold(
      appBar: AppBar(title: const Text('数据报表')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: ['本周', '本月', '本年'].map((p) {
                    final isSelected = _selectedPeriod == ['本周', '本月', '本年'].indexOf(p);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = ['本周', '本月', '本年'].indexOf(p)),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700])),
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
                      const Text('本月收入', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(currencyFormat.format(provider.monthIncome), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('支出: ${currencyFormat.format(provider.monthExpense.abs())}', style: const TextStyle(color: Colors.white70)),
                          const Spacer(),
                          Text('净收: ${currencyFormat.format(provider.monthIncome + provider.monthExpense)}', style: const TextStyle(color: Colors.white)),
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
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 5000,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: const FlTitlesData(),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      barGroups: [1, 2, 3, 4, 5, 6, 7].map((i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (i * 800).toDouble(), color: Theme.of(context).primaryColor, width: 20)]).copyWith()).toList(),
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