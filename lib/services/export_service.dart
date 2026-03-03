import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

/// ExportService handles exporting expenses to CSV and PDF formats.
class ExportService {
  /// Export expenses to CSV file and share.
  static Future<void> exportToCsv(List<ExpenseModel> expenses) async {
    final rows = <List<dynamic>>[
      ['Date', 'Time', 'Category', 'Amount', 'Description'],
      ...expenses.map((e) => [
            DateFormat('yyyy-MM-dd').format(e.date),
            e.time,
            e.category,
            e.amount.toStringAsFixed(2),
            e.description,
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Expenses - Rumi Ishi Expense Tracker',
    );
  }

  /// Export expenses to PDF file and share.
  static Future<void> exportToPdf(List<ExpenseModel> expenses,
      {String currencySymbol = '\$'}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Rumi Ishi Expense Tracker',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            headers: ['Date', 'Time', 'Category', 'Amount', 'Description'],
            data: expenses
                .map((e) => [
                      dateFormat.format(e.date),
                      e.time,
                      e.category,
                      '$currencySymbol${e.amount.toStringAsFixed(2)}',
                      e.description,
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total: $currencySymbol${total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Expenses - Rumi Ishi Expense Tracker',
    );
  }
}
