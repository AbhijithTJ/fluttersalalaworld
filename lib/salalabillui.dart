import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class SalalaBillPage extends StatelessWidget {
  final String customerName;
  final String customerAddress;
  final String customerPhoneNumber;
  final String billNo;
  final String invoiceNo;
  final String headphoneModel;
  final String date;
  final String imeiNo;
  final double totalPrice;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final String amountInWords;

  SalalaBillPage({
    Key? key,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhoneNumber,
    required this.billNo,
    required this.invoiceNo,
    required this.headphoneModel,
    required this.date,
    required this.imeiNo,
    required this.totalPrice,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.amountInWords,
  }) : super(key: key);

  // Utility to break long words for PDF rendering
  String _breakLongWords(String text, int maxLen) {
    final buffer = StringBuffer();
    int lineLen = 0;
    for (var word in text.split(' ')) {
      // If the word itself is longer than maxLen, break it
      while (word.length > maxLen) {
        if (lineLen > 0) {
          buffer.write('\n');
          lineLen = 0;
        }
        buffer.write(word.substring(0, maxLen));
        buffer.write('\n');
        word = word.substring(maxLen);
      }
      if (lineLen + word.length > maxLen) {
        buffer.write('\n');
        lineLen = 0;
      } else if (lineLen > 0) {
        buffer.write(' ');
        lineLen++;
      }
      buffer.write(word);
      lineLen += word.length;
    }
    return buffer.toString();
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final bgImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/blank_salala_bill.png')).buffer.asUint8List(),
    );

    final fontData = await rootBundle.load("assets/fonts/microsoft.ttf");
    final customFont = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Center(
                child: pw.Image(bgImage, fit: pw.BoxFit.fitWidth),
              ),
              // Customer Name
              pw.Positioned(
                left: 40.34,
                top: 228,
                child: pw.Text(customerName.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Customer Address
              pw.Positioned(
                left: 40.34,
                top: 239,
                child: pw.Text(customerAddress.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Customer Phone Number
              pw.Positioned(
                left: 40.34,
                top: 250,
                child: pw.Text(customerPhoneNumber.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Bill No
              pw.Positioned(
                left: 180,
                top: 226,
                child: pw.Text(billNo.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Invoice No
              pw.Positioned(
                left: 345,
                top: 226,
                child: pw.Text(invoiceNo.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Date
              pw.Positioned(
                left: 345,
                top: 190,
                child: pw.Text(date.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Headphone Model
              pw.Positioned(
                left: 345,
                top: 152,
                child: pw.Text(_breakLongWords(headphoneModel.toUpperCase(), 18), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Headphone Model (duplicate)
              pw.Positioned(
                left: 47,
                top: 317,
                child: pw.Text(_breakLongWords(headphoneModel.toUpperCase(), 18), style: pw.TextStyle(fontSize: 8, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // IMEI No
              pw.Positioned(
                left: 47,
                top: 336,
                child: pw.Text(imeiNo.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Total Price
              pw.Positioned(
                left: 400,
                top: 326.38,
                child: pw.Text(totalPrice.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Taxable Amount
              pw.Positioned(
                left: 143,
                top: 326.38,
                child: pw.Text(taxableAmount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // CGST
              pw.Positioned(
                left: 285,
                top: 326.38,
                child: pw.Text(cgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // SGST
              pw.Positioned(
                left: 340,
                top: 326.38,
                child: pw.Text(sgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
              ),
              // Amount in Words
              pw.Positioned(
                left: 120,
                top: 605,
                child: pw.SizedBox(
                  width: 450, // Adjust width as needed
                  child: pw.Text(amountInWords.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor(77 / 255, 77 / 255, 77 / 255, 0.6), font: customFont)),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salala Bill'),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
      ),
    );
  }
}