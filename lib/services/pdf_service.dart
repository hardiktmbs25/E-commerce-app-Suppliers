import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../data/models/invoice_model.dart';
import '../data/models/customer_model.dart';

class PdfService {
  Future<File> generateInvoicePdf(InvoiceModel invoice, CustomerModel customer) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('INVOICE')),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:'),
                      pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.address),
                      pw.Text(customer.phone),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                      pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                      pw.Text('Month: ${invoice.monthName} ${invoice.year}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Monthly Service - ${invoice.monthName}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('INR ${invoice.totalAmount}')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text('INR ${invoice.totalAmount}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('Thank you for your business!'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${invoice.invoiceNumber}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}