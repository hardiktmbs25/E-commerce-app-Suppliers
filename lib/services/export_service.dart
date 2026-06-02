import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/customer_model.dart';
import '../data/models/delivery_model.dart';

class ExportService {
  Future<File> exportCustomersToExcel(List<CustomerModel> customers) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Customers'];
    
    sheetObject.appendRow([
      TextCellValue('Name'), 
      TextCellValue('Phone'), 
      TextCellValue('Address'), 
      TextCellValue('Status'), 
      TextCellValue('Wallet Balance'), 
      TextCellValue('Pending Amount')
    ]);
    
    for (var c in customers) {
      sheetObject.appendRow([
        TextCellValue(c.name), 
        TextCellValue(c.phone), 
        TextCellValue(c.address), 
        TextCellValue(c.statusStr), 
        DoubleCellValue(c.walletBalance), 
        DoubleCellValue(c.pendingAmount)
      ]);
    }
    
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/customers_export_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  Future<File> exportDeliveriesToExcel(List<DeliveryModel> deliveries) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Deliveries'];
    
    sheetObject.appendRow([
      TextCellValue('Date'), 
      TextCellValue('Customer'), 
      TextCellValue('Product'), 
      TextCellValue('Quantity'), 
      TextCellValue('Status'), 
      TextCellValue('Amount')
    ]);
    
    for (var d in deliveries) {
      sheetObject.appendRow([
        TextCellValue(d.scheduledDate.toString()), 
        TextCellValue(d.customerName), 
        TextCellValue(d.serviceTypeStr), 
        DoubleCellValue(d.quantity), 
        TextCellValue(d.statusStr), 
        DoubleCellValue(d.amount)
      ]);
    }
    
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/deliveries_export_${DateTime.now().millisecondsSinceEpoch}.xlsx");
    await file.writeAsBytes(excel.encode()!);
    return file;
  }
}