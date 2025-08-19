import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction.dart';

class PdfReceiptApi {
  static Future<void> generateAndShare(Transaction transaction) async {
    final pdf = pw.Document();

    // Load a font that supports a wider range of characters if needed
    // final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return _buildPdfContent(transaction);
        },
      ),
    );

    // Use the printing package to share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt-transaction-${transaction.id}.pdf',
    );
  }

  static pw.Widget _buildPdfContent(Transaction transaction) {
    final dateFormat = DateFormat('E, d MMM yyyy HH:mm');
    const double dzdFontSize = 12;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Transaction Receipt',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22),
            ),
            pw.Text(
              'Institute Print Shop',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 16),
            ),
          ],
        ),
        pw.Divider(thickness: 2, height: 30),

        // Transaction Info
        _buildInfoRow('Transaction ID:', '#${transaction.id.toString().padLeft(5, '0')}'),
        _buildInfoRow('Date:', dateFormat.format(transaction.transactionDate)),
        pw.SizedBox(height: 20),

        // Details Table
        pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Divider(height: 10, thickness: 0.5),
        _buildInfoRow('Instructor:', transaction.instructorName),
        _buildInfoRow('Class:', 'Class ${transaction.className}'),
        _buildInfoRow('Printing Type:', transaction.printingType == PrintingType.recto ? 'Recto (Single-sided)' : 'Recto Verso (Double-sided)'),
        _buildInfoRow('Number of Copies:', transaction.paperCopies.toString()),
        pw.SizedBox(height: 30),

        // Payment Summary
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildPaymentRow('Total Cost:', transaction.totalCost, dzdFontSize),
                pw.SizedBox(height: 8),
                _buildPaymentRow('Amount Paid:', transaction.paidAmount, dzdFontSize),
                pw.Divider(height: 12),
                _buildPaymentRow('Remaining Balance:', transaction.remainingBalance, dzdFontSize, isBold: true),
              ],
            ),
          ),
        ),
        pw.Spacer(),

        // Footer
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'Thank you for your business!',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentRow(String label, double amount, double fontSize, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          '${amount.toStringAsFixed(2)} DZD',
          style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ],
    );
  }
}
