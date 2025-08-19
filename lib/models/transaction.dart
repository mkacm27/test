// Enum for printing type for type-safe validation
enum PrintingType {
  recto,
  rectoVerso,
}

// Enum for payment status for type-safe validation
enum PaymentStatus {
  paid,
  unpaid,
}

class Transaction {
  final int? id;
  final DateTime transactionDate;
  final String className;
  final String instructorName;
  final int paperCopies;
  final PrintingType printingType;
  final double totalCost;
  final double paidAmount;
  final PaymentStatus paymentStatus;

  // The remaining balance is a calculated property, not stored in the database.
  double get remainingBalance => totalCost - paidAmount;

  Transaction({
    this.id,
    required this.transactionDate,
    required this.className,
    required this.instructorName,
    required this.paperCopies,
    required this.printingType,
    required this.totalCost,
    required this.paidAmount,
    required this.paymentStatus,
  });

  // Converts a Transaction object into a Map object.
  // This is used when inserting/updating data into the SQLite database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionDate': transactionDate.toIso8601String(),
      'className': className,
      'instructorName': instructorName,
      'paperCopies': paperCopies,
      'printingType': printingType.toString(),
      'totalCost': totalCost,
      'paidAmount': paidAmount,
      'paymentStatus': paymentStatus.toString(),
    };
  }

  // Creates a Transaction object from a Map object.
  // This is used when reading data from the SQLite database.
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      transactionDate: DateTime.parse(map['transactionDate']),
      className: map['className'],
      instructorName: map['instructorName'],
      paperCopies: map['paperCopies'],
      printingType: PrintingType.values.firstWhere((e) => e.toString() == map['printingType']),
      totalCost: map['totalCost'],
      paidAmount: map['paidAmount'],
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.toString() == map['paymentStatus']),
    );
  }

  // Creates a copy of the Transaction instance with modified fields.
  // Useful for state management to create a new object instance instead of mutating the old one.
  Transaction copyWith({
    int? id,
    DateTime? transactionDate,
    String? className,
    String? instructorName,
    int? paperCopies,
    PrintingType? printingType,
    double? totalCost,
    double? paidAmount,
    PaymentStatus? paymentStatus,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionDate: transactionDate ?? this.transactionDate,
      className: className ?? this.className,
      instructorName: instructorName ?? this.instructorName,
      paperCopies: paperCopies ?? this.paperCopies,
      printingType: printingType ?? this.printingType,
      totalCost: totalCost ?? this.totalCost,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
