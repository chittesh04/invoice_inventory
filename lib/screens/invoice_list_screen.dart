import 'package:flutter/material.dart';
import 'package:invoice_history/services/supabase_service.dart';
import 'package:invoice_history/utils/logger_config.dart';

import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _invoices = [];
  bool _isLoading = false;
  String _uploadStatus = "";

  Future<void> _searchInvoices(String searchTerm) async {
    setState(() {
      _isLoading = true;
      _invoices = [];
      _uploadStatus = "";
    });

    List<dynamic> mobileInvoices = []; // Initialize as empty lists
    List<dynamic> vehicleInvoices = [];

    try {
      // Mobile Number Search
      mobileInvoices = await supabase
          .from('invoices')
          .select()
          .ilike('bill_to->>mobile', '%$searchTerm%')
          .order('created_at', ascending: false) as List<dynamic>; // Explicit cast

    } catch (mobileError) {
      logger.e("Mobile Search Error for term '$searchTerm': $mobileError");
      setState(() {
        _uploadStatus = "Error searching invoices by mobile. Please check logs.";
      });
    }

    try {
      // Vehicle Number Search
      vehicleInvoices = await supabase
          .from('invoices')
          .select()
          .ilike('vehicle_info->>vehicle_no', '%$searchTerm%')
          .order('created_at', ascending: false) as List<dynamic>; // Explicit cast

    } catch (vehicleError) {
      logger.e("Vehicle Search Error for term '$searchTerm': $vehicleError");
      setState(() {
        _uploadStatus = "Error searching invoices by vehicle number. Please check logs.";
      });
    }

    setState(() {
      final combinedInvoices = <dynamic>{...mobileInvoices, ...vehicleInvoices};
      _invoices = combinedInvoices.toList();
      _isLoading = false;

      if (_uploadStatus.isEmpty && _invoices.isEmpty) {
        _uploadStatus = "No invoices found for the search term."; // Indicate no results
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Enter Mobile or Vehicle Number',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: _searchInvoices,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_uploadStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _uploadStatus,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                final invoiceNumber = invoice['invoice_details']?['invoice_no'] ?? 'N/A';
                final invoiceDate = invoice['invoice_details']?['invoice_date'] ?? 'N/A';
                final totalAmount = invoice['totals']?['total_amount'] ?? 'N/A';

                return ListTile(
                  title: Text('Invoice #: $invoiceNumber'),
                  subtitle: Text('Date: $invoiceDate | Amount: ₹$totalAmount'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailScreen(invoice: invoice),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Download Invoice History (Not Implemented)',
        child: const Icon(Icons.download),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download Invoice History feature is not yet implemented.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}