import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io'; // Import dart:io for File
import '../services/invoice_extraction_service.dart';
import '../services/supabase_service.dart';
import '../utils/logger_config.dart';

class InvoiceUploadScreen extends StatefulWidget {
  const InvoiceUploadScreen({super.key});

  @override
  InvoiceUploadScreenState createState() => InvoiceUploadScreenState();
}

class InvoiceUploadScreenState extends State<InvoiceUploadScreen> {
  bool _isLoading = false;
  String _uploadStatus = "";

  Future<void> _uploadInvoice() async {
    setState(() {
      _isLoading = true;
      _uploadStatus = "Selecting PDF...";
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploadStatus = "Processing PDF...";
        });

        PlatformFile pickedFile = result.files.first;
        Uint8List? pdfBytes; // Declare as nullable

        if (pickedFile.bytes != null) {
          pdfBytes = pickedFile.bytes!; // Use bytes if available
        } else if (pickedFile.path != null) {
          pdfBytes = await _readFileBytes(pickedFile.path!); // Read bytes from path
          if (pdfBytes.isEmpty) {
            setState(() {
              _uploadStatus = "Error reading PDF file bytes from path.";
              _isLoading = false;
            });
            return; // Exit if bytes couldn't be read
          }
        } else {
          setState(() {
            _uploadStatus = "Could not get PDF file bytes or path.";
            _isLoading = false;
          });
          return; // Exit if neither bytes nor path are available
        }

 // Check if pdfBytes is not null before proceeding
        Map<String, dynamic> invoiceData = await extractInvoiceDataFromBytes(pdfBytes);
        logger.i("Extracted Data: $invoiceData");

        setState(() {
          _uploadStatus = "Storing data in Supabase...";
        });
        await storeInvoiceData(invoiceData);

        setState(() {
          _uploadStatus = "Invoice uploaded successfully!";
          _isLoading = false;
        });
            } else {
        setState(() {
          _uploadStatus = "No PDF selected.";
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error during PDF upload and processing: $e");
      setState(() {
        _uploadStatus = "Error uploading invoice. Please check logs.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Invoice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadInvoice,
                child: const Text('Upload Invoice from Storage'),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              Text(_uploadStatus, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to read file bytes from path
Future<Uint8List> _readFileBytes(String filePath) async {
  File file = File(filePath);
  return await file.readAsBytes();
}