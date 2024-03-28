import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tracking/welcome.dart';

class TestPrint extends StatelessWidget {
  const TestPrint({Key? key}) : super(key: key);

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
      body: PdfPreview(
        build: (format) => _generatePdf(format),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.nunitoExtraLight();

    // Fetch data from API
    final response =
        await http.get(Uri.parse("https://fakestoreapi.com/products"));
    if (response.statusCode == 200) {
      final List<dynamic> produkList = json.decode(response.body);

      // Add each product to the PDF
      for (final produk in produkList) {
        final String id = produk['id'].toString();
        final String title = produk['title'].toString();
        final String image = produk['image'].toString();

        // Fetch image data
        final Uint8List imageData = await _getImageData(image);

        // Add product details to the PDF
        pdf.addPage(
          pw.Page(
            build: (context) {
              return pw.Column(
                children: [
                  pw.SizedBox(
                    width: double.infinity,
                    child: pw.FittedBox(
                      child:
                          pw.Text('ID: $id', style: pw.TextStyle(font: font)),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.SizedBox(
                    width: double.infinity,
                    child: pw.FittedBox(
                      child: pw.Text('Title: $title',
                          style: pw.TextStyle(font: font)),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Image(pw.MemoryImage(imageData)),
                  pw.SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      }
    } else {
      throw Exception('Belom Ada Data!');
    }

    return pdf.save();
  }

  Future<Uint8List> _getImageData(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image from URL');
    }
  }
}

