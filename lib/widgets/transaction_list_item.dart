import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers.dart';
import '../screens/transaction_form_screen.dart';
import '../utils/pdf_generator.dart';

class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat('E, d MMM yyyy HH:mm').format(transaction.transactionDate);
    final isPaid = transaction.paymentStatus == PaymentStatus.paid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${transaction.instructorName} - Class ${transaction.className}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(isPaid ? 'Paid' : 'Unpaid'),
                  backgroundColor: isPaid ? colorScheme.primaryContainer.withOpacity(0.5) : colorScheme.errorContainer.withOpacity(0.5),
                  labelStyle: TextStyle(color: isPaid ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(formattedDate, style: theme.textTheme.bodySmall),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCostInfo('Total Cost', transaction.totalCost, theme),
                _buildCostInfo('Amount Paid', transaction.paidAmount, theme),
                _buildCostInfo('Remaining', transaction.remainingBalance, theme, isBold: true),
              ],
            ),
            const SizedBox(height: 8),
            _buildActionButtons(context, ref, isPaid),
          ],
        ),
      ),
    );
  }

  Widget _buildCostInfo(String label, double amount, ThemeData theme, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          '${amount.toStringAsFixed(2)} DZD',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isPaid) {
    return ButtonBar(
      alignment: MainAxisAlignment.end,
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      children: [
        if (!isPaid)
          TextButton(
            onPressed: () => _showMarkAsPaidConfirmation(context, ref),
            child: const Text('Mark Paid'),
          ),
        TextButton(
          onPressed: () => PdfReceiptApi.generateAndShare(transaction),
          child: const Text('Receipt'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen(transaction: transaction),
              ),
            );
          },
          child: const Text('Edit'),
        ),
        TextButton(
          onPressed: () => _showDeleteConfirmation(context, ref),
          child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }

  void _showMarkAsPaidConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Mark this transaction as fully paid? This will set the paid amount to ${transaction.totalCost.toStringAsFixed(2)} DZD.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final updatedTransaction = transaction.copyWith(
                paymentStatus: PaymentStatus.paid,
                paidAmount: transaction.totalCost,
              );
              ref.read(transactionActionsProvider.notifier).updateTransaction(updatedTransaction);
              Navigator.of(ctx).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () {
              ref.read(transactionActionsProvider.notifier).deleteTransaction(transaction.id!);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
