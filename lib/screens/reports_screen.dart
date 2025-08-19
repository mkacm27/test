import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers.dart';
import '../utils/constants.dart';

// Provider specifically for the report's date range
final reportFilterProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider that fetches transactions only for the report screen
final reportDataProvider = FutureProvider<List<Transaction>>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final selectedMonth = ref.watch(reportFilterProvider);

  final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  return dbHelper.queryTransactions(startDate: firstDay, endDate: lastDay);
});


class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _selectMonth(BuildContext context, WidgetRef ref) async {
    final selectedMonth = ref.read(reportFilterProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ref.read(reportFilterProvider.notifier).state = DateTime(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDate = ref.watch(reportFilterProvider);
    final reportDataAsync = ref.watch(reportDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(reportDate),
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () => _selectMonth(context, ref),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportDataAsync.when(
              data: (transactions) => _buildReportView(context, transactions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Failed to load report data: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(BuildContext context, List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions recorded for this month.'));
    }

    // Aggregate data
    final Map<String, int> printsByClass = {};
    final Map<String, double> costByClass = {};
    double totalMonthCost = 0;
    int totalMonthPrints = 0;

    for (final t in transactions) {
      printsByClass.update(t.className, (count) => count + t.paperCopies, ifAbsent: () => t.paperCopies);
      costByClass.update(t.className, (cost) => cost + t.totalCost, ifAbsent: () => t.totalCost);
      totalMonthCost += t.totalCost;
      totalMonthPrints += t.paperCopies;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(context, totalMonthPrints, totalMonthCost),
          const SizedBox(height: 24),
          Text('Breakdown by Class', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildClassBreakdown(context, printsByClass, costByClass),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalPrints, double totalCost) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Month Summary', style: theme.textTheme.headlineSmall),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Total Prints'),
              trailing: Text(totalPrints.toString(), style: theme.textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Total Revenue'),
              trailing: Text('${totalCost.toStringAsFixed(2)} DZD', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassBreakdown(BuildContext context, Map<String, int> prints, Map<String, double> costs) {
    final theme = Theme.of(context);
    return Column(
      children: AppConstants.classLevels.map((className) {
        final classPrints = prints[className] ?? 0;
        final classCost = costs[className] ?? 0.0;
        if (classPrints == 0) return const SizedBox.shrink(); // Don't show classes with no data

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text('Class $className', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('$classPrints copies'),
            trailing: Text('${classCost.toStringAsFixed(2)} DZD', style: theme.textTheme.titleMedium),
          ),
        );
      }).toList(),
    );
  }
}
