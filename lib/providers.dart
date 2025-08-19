import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/transaction.dart';
import 'utils/database_helper.dart';

// A simple provider for the DatabaseHelper singleton
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// The arguments for filtering and searching transactions
class TransactionFilter {
  final String keyword;
  final String? instructor;
  final String? className;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilter({
    this.keyword = '',
    this.instructor,
    this.className,
    this.startDate,
    this.endDate,
  });

  // copyWith for easily modifying filters
  TransactionFilter copyWith({
    String? keyword,
    String? instructor,
    String? className,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFilter(
      keyword: keyword ?? this.keyword,
      instructor: instructor ?? this.instructor,
      className: className ?? this.className,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Provider for the current filter state
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return TransactionFilter();
});


// Provider that fetches transactions based on the current filter
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final filter = ref.watch(transactionFilterProvider);

  return dbHelper.queryTransactions(
    keyword: filter.keyword,
    instructor: filter.instructor,
    className: filter.className,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// Notifier for performing CRUD operations and refreshing the list
class TransactionActionsNotifier extends Notifier<void> {
  @override
  void build() {
    // No initial state needed for actions
  }

  Future<void> addTransaction(Transaction transaction) async {
    final dbHelper = ref.read(databaseHelperProvider);
    await dbHelper.insert(transaction);
    ref.invalidate(transactionsProvider); // Invalidate to refetch
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final dbHelper = ref.read(databaseHelperProvider);
    await dbHelper.update(transaction);
    ref.invalidate(transactionsProvider);
  }

  Future<void> deleteTransaction(int id) async {
    final dbHelper = ref.read(databaseHelperProvider);
    await dbHelper.delete(id);
    ref.invalidate(transactionsProvider);
  }
}

// Provider for the actions notifier
final transactionActionsProvider = NotifierProvider<TransactionActionsNotifier, void>(
  TransactionActionsNotifier.new,
);
