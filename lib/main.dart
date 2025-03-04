import 'package:flutter/material.dart';
import 'package:invoice_history/screens/invoice_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/invoice_upload_screen.dart';




Future<void> main() async {
  await Supabase.initialize(
   url:  'https://vmlmgfmnvncrjfumqjnq.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtbG1nZm1udm5jcmpmdW1xam5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4OTA1NDgsImV4cCI6MjA1NjQ2NjU0OH0.DC7299FxP3hSP4tOaMORxpqO9jyIFnWAysHOHqNnMgY',
 
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automotive Repair App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Repair App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoiceUploadScreen()),
                );
              },
              child: const Text('Upload Invoice'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const  InvoiceListScreen()),
                );
              },
              child: const Text('Vehicle Service History (Placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}