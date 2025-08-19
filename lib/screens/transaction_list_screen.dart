import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../widgets/transaction_list_item.dart'; // This will be created next
import 'transaction_form_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that fetches transactions.
    // The UI will automatically rebuild when the state changes (loading, data, error).
    final transactionsAsyncValue = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement a filter dialog/bottom sheet here.
              // It would allow setting filters for date range, instructor, and class
              // by updating the `transactionFilterProvider`.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Instructor, Class, or ID...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (keyword) {
                // As the user types, update the keyword in the filter provider.
                // This will automatically trigger the `transactionsProvider` to refetch.
                ref.read(transactionFilterProvider.notifier)
                   .update((state) => state.copyWith(keyword: keyword));
              },
            ),
          ),
          Expanded(
            // Use .when to handle the different states of the async operation
            child: transactionsAsyncValue.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                // Use ListView.separated for better visual spacing
                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    // The list item will be a dedicated widget
                    return TransactionListItem(transaction: transaction);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Failed to load transactions: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
          );
        },
        tooltip: 'New Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
