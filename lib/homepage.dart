// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tracking/welcome.dart';
import 'package:file_picker/file_picker.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<dynamic> _produkList = [];
  List<bool> _printedStatusList = [];

  Future<void> _fetchData() async {
    final response =
        await http.get(Uri.parse("https://fakestoreapi.com/products"));
    if (response.statusCode == 200) {
      setState(() {
        _produkList = json.decode(response.body);
        _printedStatusList =
            List.generate(_produkList.length, (index) => false);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _printProdukInfo(int index) async {
    final Uint8List bytes = await _generatePdf(index);
    await _generateAndPrintPdf(bytes);
    setState(() {
      _printedStatusList[index] = true;
    });
  }

  Future<Uint8List> _generatePdf(int index) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ID: ${_produkList[index]['id']}',
                  style: pw.TextStyle(font: font)),
              pw.Text('Title: ${_produkList[index]['title']}',
                  style: pw.TextStyle(font: font)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _generateAndPrintPdf(Uint8List bytes) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.SizedBox(
                width: double.infinity,
                child: pw.FittedBox(
                  child:
                      pw.Text('Printing Demo', style: pw.TextStyle(font: font)),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Flexible(child: pw.Image(pw.MemoryImage(bytes))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trucking'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomeScreen(),
                ),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: _produkList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _produkList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('ID: ${_produkList[index]['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Title: ${_produkList[index]['title']}'),
                      SizedBox(height: 8),
                      // Image.network(
                      //   _produkList[index]['image'],
                      //   width: 100,
                      //   height: 100,
                      //   fit: BoxFit.cover,
                      // ),
                      SizedBox(height: 8),
                      Container(
                        color: _printedStatusList[index]
                            ? Colors.green
                            : Colors.yellow,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _printedStatusList[index]
                                ? 'Sudah Print'
                                : 'Belum Print',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: _printedStatusList[index]
                      ? ElevatedButton(
                          onPressed: null,
                          child: Text('Printed'),
                          style:
                              ElevatedButton.styleFrom(primary: Colors.green),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            _printProdukInfo(index);
                          },
                          child: Text('Print'),
                        ),
                );
              },
            ),
    );
  }
}
