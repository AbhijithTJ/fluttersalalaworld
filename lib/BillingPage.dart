import 'package:flutter/material.dart';
import 'package:wetherapp/salalabillui.dart';
import './BarcodeScannerPage.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({Key? key}) : super(key: key);

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();
  final TextEditingController billNoController = TextEditingController();
  final TextEditingController headphoneModelController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController imeiNoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();


  //pdf view

  Future<void> generateBillPdf({
    required String customerName,
    required String customerAddress,
    required String billNo,
    required String invoiceNo,
    required String headphoneModel,
    required String date,
    required String imei,
    required double price,
  }) async {
    final pdf = pw.Document();

    // Load background template image
    final bgImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/blank_salala_bill.png')).buffer.asUint8List(),
    );

    // Calculate tax
    double taxableAmount = price / 1.18;
    double cgst = taxableAmount * 0.09;
    double sgst = taxableAmount * 0.09;

    // Convert price to words
    String amountInWords = convertNumberToWords(price.round());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned(child: pw.Image(bgImage, fit: pw.BoxFit.cover)),

              // Shop Info (Fixed)
              pw.Positioned(left: 75, top: 90, child: pw.Text('Near supplyco, Meenangadi, 673591', style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 275, top: 90, child: pw.Text('8147668045\n7901753565', style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 475, top: 90, child: pw.Text('N/A', style: pw.TextStyle(fontSize: 10))), // Headphone model can also go here

              // Dynamic User Info
              pw.Positioned(left: 75, top: 130, child: pw.Text(customerAddress, style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 275, top: 130, child: pw.Text(billNo, style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 475, top: 130, child: pw.Text(date, style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 475, top: 150, child: pw.Text(invoiceNo, style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 275, top: 150, child: pw.Text(headphoneModel, style: pw.TextStyle(fontSize: 10))),

              // Table Row - Item
              pw.Positioned(left: 35, top: 235, child: pw.Text('1', style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 70, top: 235, child: pw.Text(headphoneModel, style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 210, top: 235, child: pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 285, top: 235, child: pw.Text('0', style: pw.TextStyle(fontSize: 10))), // Discount
              pw.Positioned(left: 355, top: 235, child: pw.Text(cgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 435, top: 235, child: pw.Text(sgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10))),
              pw.Positioned(left: 515, top: 235, child: pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10))),

              // Total
              pw.Positioned(left: 515, top: 310, child: pw.Text(price.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10))),

              // Grand Total in Words
              pw.Positioned(left: 75, top: 650, child: pw.Text(amountInWords.toUpperCase(), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ],
          );
        },
      ),
    );

    // Preview & Print
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }


  // amount convert into words

  String convertNumberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String twoDigits(int n) {
      if (n < 20) return units[n];
      return tens[n ~/ 10] + (n % 10 != 0 ? ' ' + units[n % 10] : '');
    }

    String convert(int n) {
      if (n >= 10000000) {
        return convert(n ~/ 10000000) + ' Crore ' + convert(n % 10000000);
      } else if (n >= 100000) {
        return convert(n ~/ 100000) + ' Lakh ' + convert(n % 100000);
      } else if (n >= 1000) {
        return convert(n ~/ 1000) + ' Thousand ' + convert(n % 1000);
      } else if (n >= 100) {
        return units[n ~/ 100] + ' Hundred ' + (n % 100 != 0 ? 'and ' + twoDigits(n % 100) : '');
      } else {
        return twoDigits(n);
      }
    }

    return convert(number).trim() + ' Rupees Only';
  }


  @override
  void dispose() {
    customerNameController.dispose();
    customerAddressController.dispose();
    billNoController.dispose();
    headphoneModelController.dispose();
    dateController.dispose();
    invoiceNoController.dispose();
    imeiNoController.dispose();
    priceController.dispose();
    super.dispose();
  }


  Future<void> _selectDate() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString()}";
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      double totalPrice = double.tryParse(priceController.text) ?? 0;
      double taxableAmount = totalPrice / 1.18;
      double cgst = taxableAmount * 0.09;
      double sgst = taxableAmount * 0.09;

      String amountInWords = convertNumberToWords(totalPrice.round());

      print("Submitted ✅");
      print("Name: ${customerNameController.text}");
      print("IMEI: ${imeiNoController.text}");
      print("Total Price: ₹${totalPrice.toStringAsFixed(2)}");
      print("Taxable Amount: ₹${taxableAmount.toStringAsFixed(2)}");
      print("CGST (9%): ₹${cgst.toStringAsFixed(2)}");
      print("SGST (9%): ₹${sgst.toStringAsFixed(2)}");
      print("Amount in Words: $amountInWords");

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Billing Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Price: ₹${totalPrice.toStringAsFixed(2)}'),
              Text('Taxable Value: ₹${taxableAmount.toStringAsFixed(2)}'),
              Text('CGST (9%): ₹${cgst.toStringAsFixed(2)}'),
              Text('SGST (9%): ₹${sgst.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('In Words: $amountInWords'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    Navigator.push(context, MaterialPageRoute(builder: (context)=>SalalaBillPage(), ));
    //calling pdf
    generateBillPdf(
      customerName: customerNameController.text,
      customerAddress: customerAddressController.text,
      billNo: billNoController.text,
      invoiceNo: invoiceNoController.text,
      headphoneModel: headphoneModelController.text,
      date: dateController.text,
      imei: imeiNoController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
    );


  }



  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing Details"),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Date',
                    icon: Icons.calendar_today,
                    controller: dateController,
                    keyboardType: TextInputType.datetime,
                    onTap: _selectDate,
                  ),
                  _buildTextField(
                    label: 'Bill No',
                    icon: Icons.receipt,
                    controller: billNoController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'Invoice Number',
                    icon: Icons.description,
                    controller: invoiceNoController,
                  ),
                  _buildTextField(
                    label: 'Customer Name',
                    icon: Icons.person,
                    controller: customerNameController,
                  ),
                  _buildTextField(
                    label: 'Customer Address',
                    icon: Icons.home,
                    controller: customerAddressController,
                  ),
                  _buildTextField(
                    label: 'Headphone Model',
                    icon: Icons.headphones,
                    controller: headphoneModelController,
                  ),

                  /// IMEI FIELD WITH SCANNER
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: imeiNoController,
                            decoration: InputDecoration(
                              labelText: 'IMEI Number',
                              prefixIcon: Icon(Icons.qr_code, color: colorScheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant,
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Enter IMEI Number' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          tooltip: 'Scan IMEI',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BarcodeScannerPage(
                                  onScanned: (value) {
                                    setState(() {
                                      imeiNoController.text = value;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),

                  _buildTextField(
                    label: 'Price',
                    icon: Icons.price_check,
                    controller: priceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








