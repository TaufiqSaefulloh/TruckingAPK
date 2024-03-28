// ignore_for_file: unnecessary_null_comparison, unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final int? idSopir; // Jadikan idSopir opsional dengan menambahkan tanda tanya

  HomePage({this.idSopir}); // Tetapkan idSopir sebagai opsional

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> sopirData = [];
  Map<int, bool> printedStatus = {};

  @override
  void initState() {
    super.initState();
    if (widget.idSopir != null) {
      // Periksa jika idSopir tidak null
      fetchSopirData(widget.idSopir!); // Gunakan idSopir jika tidak null
    } else {
      // Lakukan sesuatu jika idSopir null (misalnya, tampilkan pesan kesalahan)
    }
    loadPrintedStatus();
  }

  Future<void> fetchSopirData(int idSopir) async {
    final String apiUrl = 'http://localhost:8000/api/sopir/$idSopir';
    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      setState(() {
        sopirData = jsonDecode(response.body);

      });
    } else {
      throw Exception('Failed to load data');
    }
    Fluttertoast.showToast(
        msg: "This is Center Short Toast",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<void> loadPrintedStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      printedStatus = Map<int, bool>.from(
          jsonDecode(prefs.getString('printedStatus') ?? '{}'));
    });
  }

  Future<void> savePrintedStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('printedStatus', jsonEncode(printedStatus));
  }

  Future<void> printPdf(int idSopir) async {
    final pdf = pw.Document();

    // Fetch sopir data for given idSopir
    final sopir = sopirData.firstWhere((data) => data['id'] == idSopir);

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ID: ${sopir['id']}'),
              pw.Text('Nama: ${sopir['nama_sopir']}'),
              pw.Text('Email: ${sopir['email']}'),
              // Add more fields as needed
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // Save PDF and print
    final output = await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );

    // Update printed status after printing is completed
    if (output != null) {
      setState(() {
        printedStatus[idSopir] = true;
      });
      await savePrintedStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print success'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> printLocalPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      Printing.layoutPdf(onLayout: (_) async => await file.readAsBytes());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trucking'),
      ),
      body: sopirData.isEmpty
          ? Center(
              child: Text(
                'Tidak ada data sopir',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: sopirData.length,
              itemBuilder: (context, index) {
                final sopir = sopirData[index];
                final int id = sopir['id'];
                final String namaSopir = sopir['nama_sopir'];

                return ListTile(
                  title: Text('ID: $id'),
                  subtitle: Text('Nama: $namaSopir'),
                  trailing: printedStatus[id] == true
                      ? Icon(Icons.done, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Perhatian!'),
                                  content: Text(
                                      'Tombol print hanya berlaku satu kali setelah di klik, jika status berubah setelah di klik dan belum melakukan pencetakan segera hubungi admin'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await printPdf(id);
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text('Print'),
                        ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: printLocalPdf,
        label: Text('Print Local PDF'),
        icon: Icon(Icons.add),
      ),
    );
  }
}
