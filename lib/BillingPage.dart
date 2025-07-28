import 'package:flutter/material.dart';
import 'package:wetherapp/salalabillui.dart';
import './BarcodeScannerPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wetherapp/services/number_generator_service.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({Key? key}) : super(key: key);

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final _formKey = GlobalKey<FormState>();
  final NumberGeneratorService _numberGeneratorService = NumberGeneratorService();

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();
  final TextEditingController customerPhoneNumberController = TextEditingController();
  final TextEditingController billNoController = TextEditingController();
  final TextEditingController headphoneModelController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController imeiNoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateNumbers();
  }

  Future<void> _generateNumbers() async {
    try {
      int nextBillNo = await _numberGeneratorService.getNextNumber('bill_number');
      int nextInvoiceNo = await _numberGeneratorService.getNextNumber('invoice_number');

      setState(() {
        billNoController.text = nextBillNo.toString();
        invoiceNoController.text = 'H' + nextInvoiceNo.toString();
      });
    } catch (e) {
      print('Error generating numbers: $e');
      // Handle error, e.g., show a snackbar or alert
    }
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

  Future<void> _submitForm() async {
    // Explicitly unfocus any active text field before processing the form
    FocusManager.instance.primaryFocus?.unfocus();

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

      // Prepare data for Firestore
      Map<String, dynamic> billingData = {
        'customerName': customerNameController.text,
        'customerAddress': customerAddressController.text,
        'customerPhoneNumber': customerPhoneNumberController.text,
        'billNo': billNoController.text,
        'invoiceNo': invoiceNoController.text,
        'headphoneModel': headphoneModelController.text,
        'date': dateController.text,
        'imeiNo': imeiNoController.text,
        'totalPrice': totalPrice,
        'taxableAmount': taxableAmount,
        'cgst': cgst,
        'sgst': sgst,
        'amountInWords': amountInWords,
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
      };

      // Send data to Firestore
      try {
        await FirebaseFirestore.instance.collection('bills').add(billingData);
        print('Billing data successfully sent to Firestore!');
      } catch (e) {
        print('Error sending billing data to Firestore: $e');
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Billing Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Name: ${customerNameController.text}'),
              Text('Customer Address: ${customerAddressController.text}'),
              Text('Customer Phone: ${customerPhoneNumberController.text}'),
              Text('Bill No: ${billNoController.text}'),
              Text('Invoice No: ${invoiceNoController.text}'),
              Text('Headphone Model: ${headphoneModelController.text}'),
              Text('Date: ${dateController.text}'),
              Text('IMEI: ${imeiNoController.text}'),
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
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context); // Close the dialog
                await Future.delayed(const Duration(milliseconds: 100)); // Small delay
                Navigator.push(context, MaterialPageRoute(builder: (context) => SalalaBillPage(
                  customerName: customerNameController.text,
                  customerAddress: customerAddressController.text,
                  customerPhoneNumber: customerPhoneNumberController.text,
                  billNo: billNoController.text,
                  invoiceNo: invoiceNoController.text,
                  headphoneModel: headphoneModelController.text,
                  date: dateController.text,
                  imeiNo: imeiNoController.text,
                  totalPrice: totalPrice,
                  taxableAmount: taxableAmount,
                  cgst: cgst,
                  sgst: sgst,
                  amountInWords: amountInWords,
                ))); // Navigate to next page
              },
            ),
          ],
        ),
      );
    }
  }



  Widget _buildTextField({
    Key? key,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
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
                    readOnly: true, // Make read-only
                  ),
                  _buildTextField(
                    label: 'Invoice Number',
                    icon: Icons.description,
                    controller: invoiceNoController,
                    readOnly: true, // Make read-only
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
                    label: 'Customer Mobile Number',
                    icon: Icons.phone,
                    controller: customerPhoneNumberController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    label: 'Headphone Model',
                    icon: Icons.phone_android,
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








