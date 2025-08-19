import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers.dart';
import '../utils/constants.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction; // Null if creating, non-null if editing

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _dateController;
  late TextEditingController _copiesController;
  late TextEditingController _paidAmountController;

  // Form state
  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  String? _selectedInstructor;
  PrintingType _selectedPrintingType = PrintingType.recto;
  bool _manualStatusOverride = false;
  PaymentStatus _manualPaymentStatus = PaymentStatus.unpaid;

  // Calculated state
  double _totalCost = 0.0;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _copiesController = TextEditingController();
    _paidAmountController = TextEditingController();

    if (_isEditing) {
      // If editing, populate the form with existing transaction data
      final t = widget.transaction!;
      _selectedDate = t.transactionDate;
      _selectedClass = t.className;
      _selectedInstructor = t.instructorName;
      _selectedPrintingType = t.printingType;
      _copiesController.text = t.paperCopies.toString();
      _paidAmountController.text = t.paidAmount.toStringAsFixed(2);
      _manualPaymentStatus = t.paymentStatus;

      // Determine if the status was a manual override
      final calculatedStatus = (t.totalCost - t.paidAmount <= 0) ? PaymentStatus.paid : PaymentStatus.unpaid;
      if (t.paymentStatus != calculatedStatus) {
        _manualStatusOverride = true;
      }
    }

    _dateController.text = DateFormat('E, d MMM yyyy HH:mm').format(_selectedDate);
    _calculateTotalCost(); // Initial calculation

    // Add listeners to recalculate on change
    _copiesController.addListener(_calculateTotalCost);
    _paidAmountController.addListener(_calculateTotalCost);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _copiesController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _calculateTotalCost() {
    final copies = int.tryParse(_copiesController.text) ?? 0;
    final pricePerCopy = _selectedPrintingType == PrintingType.recto
        ? AppConstants.rectoPrice
        : AppConstants.rectoVersoPrice;

    setState(() {
      _totalCost = copies * pricePerCopy;
    });
  }

  PaymentStatus get _currentPaymentStatus {
    if (_manualStatusOverride) {
      return _manualPaymentStatus;
    }
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_totalCost > 0 && paidAmount >= _totalCost) ? PaymentStatus.paid : PaymentStatus.unpaid;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateController.text = DateFormat('E, d MMM yyyy HH:mm').format(_selectedDate);
    });
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newTransaction = Transaction(
        id: widget.transaction?.id,
        transactionDate: _selectedDate,
        className: _selectedClass!,
        instructorName: _selectedInstructor!,
        paperCopies: int.parse(_copiesController.text),
        printingType: _selectedPrintingType,
        totalCost: _totalCost,
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0.0,
        paymentStatus: _currentPaymentStatus,
      );

      final notifier = ref.read(transactionActionsProvider.notifier);
      if (_isEditing) {
        notifier.updateTransaction(newTransaction);
      } else {
        notifier.addTransaction(newTransaction);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'New Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Transaction Date', prefixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedClass,
                items: AppConstants.classLevels.map((c) => DropdownMenuItem(value: c, child: Text('Class $c'))).toList(),
                onChanged: (value) => setState(() => _selectedClass = value),
                decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.school_outlined)),
                validator: (v) => v == null ? 'Please select a class' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedInstructor,
                items: AppConstants.instructors.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (value) => setState(() => _selectedInstructor = value),
                decoration: const InputDecoration(labelText: 'Instructor', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null ? 'Please select an instructor' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PrintingType>(
                      initialValue: _selectedPrintingType,
                      items: PrintingType.values.map((pt) => DropdownMenuItem(value: pt, child: Text(pt == PrintingType.recto ? 'Recto' : 'Recto Verso'))).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPrintingType = value;
                            _calculateTotalCost();
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _copiesController,
                      decoration: const InputDecoration(labelText: 'No. of Copies'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == 0) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Cost Summary', style: theme.textTheme.titleLarge),
              const Divider(),
              ListTile(
                title: const Text('Total Cost'),
                trailing: Text('${_totalCost.toStringAsFixed(2)} DZD', style: theme.textTheme.titleMedium),
              ),
              TextFormField(
                controller: _paidAmountController,
                decoration: const InputDecoration(labelText: 'Paid Amount (DZD)', prefixIcon: Icon(Icons.payment)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) => (v == null || v.isEmpty) ? 'Enter a paid amount' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Manually Set Payment Status'),
                value: _manualStatusOverride,
                onChanged: (value) => setState(() => _manualStatusOverride = value),
              ),
              if (_manualStatusOverride)
                DropdownButtonFormField<PaymentStatus>(
                  initialValue: _manualPaymentStatus,
                  items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (value) => setState(() => _manualPaymentStatus = value!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Save Transaction'),
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
