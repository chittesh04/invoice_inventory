import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger_config.dart';

SupabaseClient get supabase => Supabase.instance.client;

Future<void> storeInvoiceData(Map<String, dynamic> data) async {
  try {
    final response = await supabase
        .from('invoices')
        .insert({
      'invoice_no': data['invoice_details']['invoice_no'],
      'invoice_date': data['invoice_details']['invoice_date'],
      'due_date': data['invoice_details']['due_date'],
      'vehicle_info': data['vehicle_info'],
      'bill_to': data['bill_to'],
      'ship_to': data['ship_to'],
      'items': data['items'],
      'totals': data['totals'],
      'mobile' : data['bill_to']['mobile'],
      'vehicle_no' : data['vehicle_info']['vehicle_no'],
    });

    if (response.error != null) {
      logger.e('Supabase Insert Error: ${response.error!.message}');
    } else {
      logger.i('Invoice data successfully stored in Supabase!');
    }
  } catch (e) {
    logger.e('Error storing invoice data in Supabase: $e');
  }
}