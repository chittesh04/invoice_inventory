import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:invoice_history/utils/logger_config.dart'; // Keep logger import

// Removed unnecessary import: import 'package:supabase_flutter/supabase_flutter.dart';
// Removed unnecessary import: import 'package:invoice_history/services/supabase_service.dart';


class InvoiceDetailScreen extends StatelessWidget {
  final dynamic invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  // Function to launch WhatsApp with a pre-populated message
  Future<void> _launchWhatsApp(BuildContext context) async {
    String? phone = invoice['bill_to']?['mobile']; // Null-safe access for mobile number
    if (phone == null || phone.isEmpty) {
      if (!mounted(context)) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number not available for WhatsApp.'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit if no phone number
    }

    String invoiceNumber = invoice['invoice_details']?['invoice_no'] ?? 'N/A';
    String invoiceDate = invoice['invoice_details']?['invoice_date'] ?? 'N/A';
    String totalAmount = invoice['totals']?['total_amount'] ?? 'N/A';

    String message =
        "Dear Customer, your invoice #$invoiceNumber dated $invoiceDate shows an amount of ₹$totalAmount. Please contact us for further details."; // Use ₹ symbol

    var whatsappUrl = Uri.parse("whatsapp://send?phone=+91$phone&text=${Uri.encodeComponent(message)}"); // Assuming Indian numbers, add country code if needed

    if (await canLaunchUrl(whatsappUrl)) {
      if (!mounted(context)) return; // Add mounted check before using context
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted(context)) return; // Add mounted check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch WhatsApp. Please ensure WhatsApp is installed.'),
          duration: Duration(seconds: 3),
        ),
      );
      logger.e('Could not launch WhatsApp'); // Log the error
    }
  }

  bool mounted(BuildContext context) => context.mounted; // Helper function to check if context is mounted


  @override
  Widget build(BuildContext context) {
    String invoiceNumber = invoice['invoice_details']?['invoice_no'] ?? 'N/A'; // Null-safe access
    String invoiceDate = invoice['invoice_details']?['invoice_date'] ?? 'N/A';
    String dueDate = invoice['invoice_details']?['due_date'] ?? 'N/A';
    String vehicleModel = invoice['vehicle_info']?['model'] ?? 'N/A';
    String vehicleKm = invoice['vehicle_info']?['km'] ?? 'N/A';
    String vehicleNo = invoice['vehicle_info']?['vehicle_no'] ?? 'N/A';
    String billToName = invoice['bill_to']?['name'] ?? 'N/A';
    String billToMobile = invoice['bill_to']?['mobile'] ?? 'N/A';
    String shipToName = invoice['ship_to']?['name'] ?? 'N/A';
    String shipToMobile = invoice['ship_to']?['mobile'] ?? 'N/A';
    List<dynamic> items = invoice['items'] ?? []; // Ensure items is not null
    String subtotal = invoice['totals']?['subtotal'] ?? 'N/A';
    String taxableAmount = invoice['totals']?['taxable_amount'] ?? 'N/A';
    String totalAmount = invoice['totals']?['total_amount'] ?? 'N/A';


    return Scaffold(
      appBar: AppBar(title: Text('Invoice Details: $invoiceNumber')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Removed: crossAxisAlignment: CrossAxisAlignment.start, // ListView does not have crossAxisAlignment
          children: [
            Text("Invoice Number: $invoiceNumber", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [const Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(invoiceDate)]), // Use const Text
            Row(children: [const Text("Due Date: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(dueDate)]), // Use const Text

            const SizedBox(height: 20),
            const Text("Vehicle Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use const Text
            const SizedBox(height: 10),
            Row(children: [const Text("Model: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(vehicleModel)]), // Use const Text
            Row(children: [const Text("KM: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(vehicleKm)]), // Use const Text
            Row(children: [const Text("Vehicle No: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(vehicleNo)]), // Use const Text

            const SizedBox(height: 20),
            const Text("Billing Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use const Text
            const SizedBox(height: 10),
            Row(children: [const Text("Bill To Name: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(billToName)]), // Use const Text
            Row(children: [const Text("Bill To Mobile: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(billToMobile)]), // Use const Text

            const SizedBox(height: 20),
            const Text("Shipping Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use const Text
            const SizedBox(height: 10),
            Row(children: [const Text("Ship To Name: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(shipToName)]), // Use const Text
            Row(children: [const Text("Ship To Mobile: ", style: TextStyle(fontWeight: FontWeight.bold)), Text(shipToMobile)]), // Use const Text

            const SizedBox(height: 20),
            const Text("Items/Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use const Text
            const SizedBox(height: 10),
            DataTable(
              columns: const [
                DataColumn(label: Text('S.No')),
                DataColumn(label: Text('Description')),
              ],
              rows: items.map<DataRow>((item) => DataRow(cells: [
                DataCell(Text(item['sno']?.toString() ?? 'N/A')),
                DataCell(Text(item['description']?.toString() ?? 'N/A')),
              ])).toList(),
            ),

            const SizedBox(height: 20),
            const Text("Totals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Use const Text
            const SizedBox(height: 10),
            Row(children: [const Text("Subtotal: ", style: TextStyle(fontWeight: FontWeight.bold)), Text('₹$subtotal')]), // Use const Text
            Row(children: [const Text("Taxable Amount: ", style: TextStyle(fontWeight: FontWeight.bold)), Text('₹$taxableAmount')]), // Use const Text
            Row(children: [const Text("Total Amount: ", style: TextStyle(fontWeight: FontWeight.bold)), Text('₹$totalAmount')]), // Use const Text


            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(context), // Pass context to _launchWhatsApp
              icon: const Icon(Icons.message),
              label: const Text("Notify via WhatsApp"),
            ),
          ],
        ),
      ),
    );
  }
}