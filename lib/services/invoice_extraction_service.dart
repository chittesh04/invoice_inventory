import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts invoice data from a PDF document provided as bytes.
Future<Map<String, dynamic>> extractInvoiceDataFromBytes(Uint8List bytes) async {
  final document = PdfDocument(inputBytes: bytes);
  final text = PdfTextExtractor(document).extractText();
  document.dispose();

  Map<String, dynamic> data = {
    "invoice_details": <String, String>{},
    "vehicle_info": <String, String>{},
    "bill_to": <String, String>{},
    "ship_to": <String, String>{},
    "items": <Map<String, String>>[],
    "totals": <String, String>{},
  };

  // --- Invoice Details ---
  RegExp invoiceNoExp = RegExp(r"Invoice No\.\s*(\S+)");
  var invoiceNoMatch = invoiceNoExp.firstMatch(text);
  if (invoiceNoMatch != null) {
    data["invoice_details"]["invoice_no"] = invoiceNoMatch.group(1)!;
  }

  RegExp invoiceDateExp = RegExp(r"Invoice Date\s*(\S+)");
  var invoiceDateMatch = invoiceDateExp.firstMatch(text);
  if (invoiceDateMatch != null) {
    data["invoice_details"]["invoice_date"] = invoiceDateMatch.group(1)!;
  }

  RegExp dueDateExp = RegExp(r"Due Date\s*(\S+)");
  var dueDateMatch = dueDateExp.firstMatch(text);
  if (dueDateMatch != null) {
    data["invoice_details"]["due_date"] = dueDateMatch.group(1)!;
  }

  // --- Vehicle Info ---
  RegExp vehicleModelExp = RegExp(r"Vehicle Model\.\s*(.+)");
  var vehicleModelMatch = vehicleModelExp.firstMatch(text);
  if (vehicleModelMatch != null) {
    data["vehicle_info"]["model"] = vehicleModelMatch.group(1)!.trim();
  }

  RegExp kmExp = RegExp(r"KM\.\s*(\d+)");
  var kmMatch = kmExp.firstMatch(text);
  if (kmMatch != null) {
    data["vehicle_info"]["km"] = kmMatch.group(1)!;
  }

  RegExp vehicleNoExp = RegExp(r"Vehicle No\.\s*(\S+)");
  var vehicleNoMatch = vehicleNoExp.firstMatch(text);
  if (vehicleNoMatch != null) {
    data["vehicle_info"]["vehicle_no"] = vehicleNoMatch.group(1)!;
  }

  // --- BILL TO and SHIP TO ---
  RegExp billToExp = RegExp(r"BILL TO\s+([^\n]+)(?:\n\s*Mobile\s*:\s*(\d+))?");
  var billToMatch = billToExp.firstMatch(text);
  if (billToMatch != null) {
    data["bill_to"]["name"] = billToMatch.group(1)!.trim();
    if (billToMatch.groupCount >= 2 && billToMatch.group(2) != null) {
      data["bill_to"]["mobile"] = billToMatch.group(2)!;
    }
  }

  RegExp shipToExp = RegExp(r"SHIP TO\s+([^\n]+)(?:\n\s*Mobile\s*:\s*(\d+))?");
  var shipToMatch = shipToExp.firstMatch(text);
  if (shipToMatch != null) {
    data["ship_to"]["name"] = shipToMatch.group(1)!.trim();
    if (shipToMatch.groupCount >= 2 && shipToMatch.group(2) != null) {
      data["ship_to"]["mobile"] = shipToMatch.group(2)!;
    }
  }

  // --- Items Table ---
  RegExp itemsSectionExp = RegExp(r"S\.NO\.\s+ITEMS/SERVICES.*?\n(.*?)(?=\nSUBTOTAL)", dotAll: true);
  var itemsSectionMatch = itemsSectionExp.firstMatch(text);
  if (itemsSectionMatch != null) {
    String itemsText = itemsSectionMatch.group(1)!.trim();
    RegExp itemsExp = RegExp(r"^(\d+)\s+(.+?)\s+[\d\.]+\s+\w+\s+[\d,]+\s+[\d,]+", multiLine: true);
    Iterable<RegExpMatch> itemsMatches = itemsExp.allMatches(itemsText);
    List<Map<String, String>> itemsList = [];
    for (var match in itemsMatches) {
      itemsList.add({
        "sno": match.group(1)!,
        "description": match.group(2)!,
      });
    }
    data["items"] = itemsList;
  }

  // --- Totals ---
  RegExp subtotalExp = RegExp(r"SUBTOTAL\s*-\s*₹\s*([\d,]+)");
  var subtotalMatch = subtotalExp.firstMatch(text);
  if (subtotalMatch != null) {
    data["totals"]["subtotal"] = subtotalMatch.group(1)!.replaceAll(',', '');
  }

  RegExp taxableExp = RegExp(r"TAXABLE AMOUNT\s*₹\s*([\d,]+)");
  var taxableMatch = taxableExp.firstMatch(text);
  if (taxableMatch != null) {
    data["totals"]["taxable_amount"] = taxableMatch.group(1)!.replaceAll(',', '');
  }

  RegExp totalExp = RegExp(r"TOTAL AMOUNT\s*₹\s*([\d,]+)");
  var totalMatch = totalExp.firstMatch(text);
  if (totalMatch != null) {
    data["totals"]["total_amount"] = totalMatch.group(1)!.replaceAll(',', '');
  }

  return data;
}


/// Extracts invoice data from a PDF document loaded from assets.
Future<Map<String, dynamic>> extractInvoiceDataFromAsset(String assetPath) async {
  final ByteData bytesData = await rootBundle.load(assetPath);
  final Uint8List bytes = bytesData.buffer.asUint8List();
  return extractInvoiceDataFromBytes(bytes);
}