import 'package:flutter/material.dart';
import 'package:invoice_history/services/supabase_service.dart';
import 'package:invoice_history/utils/logger_config.dart';
import 'package:invoice_history/screens/invoice_detail_screen.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart'; // Add permission_handler

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
  List<Contact> _contacts = [];
  List<String> _contactSuggestions = [];

  @override
  void initState() {
    super.initState();
    _getContacts();
  }

  Future<void> _getContacts() async {
    var status = await Permission.contacts.status;
    if (status.isDenied) {
      status = await Permission.contacts.request();
      if (status.isDenied) {
        setState(() {
          _uploadStatus =
              "Contacts permission denied. Please enable in settings for contact suggestions.";
        });
        return;
      }
    }

    if (status.isGranted) {
      try {
        Iterable<Contact> contacts = await ContactsService.getContacts();
        setState(() {
          _contacts = contacts.toList();
        });
      } catch (e) {
        logger.e("Error fetching contacts: $e");
        setState(() {
          _uploadStatus = "Error fetching contacts. Please check logs.";
        });
      }
    }
  }

  Future<void> _searchInvoices(String searchTerm) async {
    setState(() {
      _isLoading = true;
      _invoices = [];
      _uploadStatus = "";
      _contactSuggestions = [];
    });

    List<dynamic> mobileInvoices = [];
    List<dynamic> vehicleInvoices = [];

    try {
      mobileInvoices = await supabase
          .from('invoices')
          .select()
          .ilike('bill_to->>mobile', '%$searchTerm%')
          .order('created_at', ascending: false) as List<dynamic>;
    } catch (mobileError) {
      logger.e("Mobile Search Error for term '$searchTerm': $mobileError");
      setState(() {
        _uploadStatus = "Error searching invoices by mobile. Please check logs.";
      });
    }

    try {
      vehicleInvoices = await supabase
          .from('invoices')
          .select()
          .ilike('vehicle_info->>vehicle_no', '%$searchTerm%')
          .order('created_at', ascending: false) as List<dynamic>;
    } catch (vehicleError) {
      logger.e("Vehicle Search Error for term '$searchTerm': $vehicleError");
      setState(() {
        _uploadStatus =
            "Error searching invoices by vehicle number. Please check logs.";
      });
    }

    setState(() {
      final combinedInvoices = <dynamic>{...mobileInvoices, ...vehicleInvoices};
      _invoices = combinedInvoices.toList();
      _isLoading = false;

      if (_uploadStatus.isEmpty && _invoices.isEmpty) {
        _uploadStatus = "No invoices found for the search term.";
      }
    });
  }

  void _updateSuggestions(String input) {
    setState(() {
      _contactSuggestions = _contacts
          .where((contact) {
            bool nameMatch = contact.displayName != null &&
                contact.displayName!.toLowerCase().contains(input.toLowerCase());

            bool phoneMatch = contact.phones != null &&
                contact.phones!.any((phone) =>
                    phone.value != null &&
                    phone.value!.replaceAll(RegExp(r'[^\d]'), '').contains(input.replaceAll(RegExp(r'[^\d]'), ''))); //Remove non-digit characters for matching

            return nameMatch || phoneMatch;
          })
          .map((contact) => contact.displayName!)
          .toList();
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
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                _updateSuggestions(textEditingValue.text);
                return _contactSuggestions;
              },
              onSelected: (String suggestion) {
                _searchController.text = suggestion;
                _searchInvoices(suggestion);
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Enter Mobile or Vehicle Number or Contact Name',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (String value) {
                    onFieldSubmitted();
                    _searchInvoices(value);
                  },
                  onChanged: (String value) {
                    _updateSuggestions(value);
                  },
                  textInputAction: TextInputAction.search,
                );
              },
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
                final invoiceNumber =
                    invoice['invoice_details']?['invoice_no'] ?? 'N/A';
                final invoiceDate =
                    invoice['invoice_details']?['invoice_date'] ?? 'N/A';
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
    );
  }
}