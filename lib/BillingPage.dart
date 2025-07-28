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
  bool _isNumberGenerationFailed = false;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerAddressController = TextEditingController();
  final TextEditingController customerPhoneNumberController = TextEditingController();
  final TextEditingController billNoController = TextEditingController();
  final TextEditingController headphoneModelController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController invoiceNoController = TextEditingController();
  final TextEditingController imeiNoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _peekAndDisplayNumbers();
    
    // Add listener to IMEI field for autofill
    imeiNoController.addListener(_onImeiChanged);
  }

  void _onImeiChanged() {
    final imei = imeiNoController.text.trim();
    if (imei.length >= 10) { // Start searching when IMEI has at least 10 digits
      _searchMobileByImei(imei);
    }
  }

  Future<void> _searchMobileByImei(String imei) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('type', isEqualTo: 'Mobile')
          .where('imei', isEqualTo: imei)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final product = querySnapshot.docs.first.data();
        
        // Auto-fill model and price, but keep them editable
        setState(() {
          headphoneModelController.text = product['model'] ?? product['name'] ?? '';
          priceController.text = product['price']?.toString() ?? '';
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mobile found: ${product['model'] ?? product['name']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Clear fields if no mobile found
        if (imei.length == 15) { // Only show message for complete IMEI
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No mobile found with this IMEI'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error searching mobile by IMEI: $e');
    }
  }

  Future<void> _generateNumbers() async {
    try {
      // This method is now used to display the *next* numbers on page load
      // and to increment and get the *actual* numbers on submit.
      // The logic here will be adjusted based on where it's called.
      // For initState, we'll peek; for submit, we'll increment.
    } catch (e) {
      print('Error generating numbers: $e');
      // Handle error, e.g., show a snackbar or alert
    }
  }

  Future<void> _peekAndDisplayNumbers() async {
    try {
      int nextBillNo = await _numberGeneratorService.peekNextNumber('bill_number');
      int nextInvoiceNo = await _numberGeneratorService.peekNextNumber('invoice_number');

      setState(() {
        billNoController.text = nextBillNo.toString();
        invoiceNoController.text = 'H' + nextInvoiceNo.toString();
      });
    } catch (e) {
      print('Error peeking numbers: $e');
      setState(() {
        _isNumberGenerationFailed = true;
      });
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
    remarkController.dispose();
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

      // Show validation dialog first, increment numbers only after OK is pressed
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => AlertDialog(
          title: const Text('Billing Summary'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${customerNameController.text}'),
                  Text('Phone: ${customerPhoneNumberController.text}'),
                  Text('Bill No: ${billNoController.text}'),
                  Text('Invoice No: ${invoiceNoController.text}'),
                  Text('Model: ${headphoneModelController.text}'),
                  Text('Date: ${dateController.text}'),
                  Text('IMEI: ${imeiNoController.text}'),
                  const Divider(),
                  Text('Total: ₹${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Taxable: ₹${taxableAmount.toStringAsFixed(2)}'),
                  Text('CGST: ₹${cgst.toStringAsFixed(2)}'),
                  Text('SGST: ₹${sgst.toStringAsFixed(2)}'),
                  if (remarkController.text.isNotEmpty) ...[
                    const Divider(),
                    Text('Remark: ${remarkController.text}'),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // Close the dialog first
                Navigator.pop(context);
                
                // Call the processing method
                _processFormSubmission(totalPrice, taxableAmount, cgst, sgst, amountInWords);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _processFormSubmission(double totalPrice, double taxableAmount, double cgst, double sgst, String amountInWords) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing...'),
            ],
          ),
        );
      },
    );
    
    // Now increment numbers and save to Firestore
    String finalBillNo = billNoController.text;
    String finalInvoiceNo = invoiceNoController.text;
    bool isSuccess = false;
    
    if (!_isNumberGenerationFailed) {
      try {
        // Get the actual numbers for this bill (increment and use)
        int actualBillNo = await _numberGeneratorService.incrementAndGetNextNumber('bill_number');
        int actualInvoiceNo = await _numberGeneratorService.incrementAndGetNextNumber('invoice_number');
        
        // Use these numbers for the current bill
        finalBillNo = actualBillNo.toString();
        finalInvoiceNo = 'H' + actualInvoiceNo.toString();
        
        // Now peek at what the NEXT numbers will be for the form
        int nextBillNo = await _numberGeneratorService.peekNextNumber('bill_number');
        int nextInvoiceNo = await _numberGeneratorService.peekNextNumber('invoice_number');
        
        // Update the controllers to show the next available numbers
        if (mounted) {
          setState(() {
            billNoController.text = nextBillNo.toString();
            invoiceNoController.text = 'H' + nextInvoiceNo.toString();
          });
        }
      } catch (e) {
        print('Error incrementing numbers: $e');
        // Use the current numbers if increment fails
      }
    }

    // Prepare data for Firestore with final numbers
    Map<String, dynamic> billingData = {
      'customerName': customerNameController.text,
      'customerAddress': customerAddressController.text,
      'customerPhoneNumber': customerPhoneNumberController.text,
      'billNo': finalBillNo,
      'invoiceNo': finalInvoiceNo,
      'headphoneModel': headphoneModelController.text,
      'date': dateController.text,
      'imeiNo': imeiNoController.text,
      'totalPrice': totalPrice,
      'taxableAmount': taxableAmount,
      'cgst': cgst,
      'sgst': sgst,
      'amountInWords': amountInWords,
      'remark': remarkController.text, // Save remark to Firestore only
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Send data to Firestore
    try {
      await FirebaseFirestore.instance.collection('bills').add(billingData);
      print('Billing data successfully sent to Firestore!');
      isSuccess = true;
    } catch (e) {
      print('Error sending billing data to Firestore: $e');
      isSuccess = false;
    }

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (isSuccess) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully committed to database!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Clear all form fields
      if (mounted) {
        setState(() {
          customerNameController.clear();
          customerAddressController.clear();
          customerPhoneNumberController.clear();
          headphoneModelController.clear();
          dateController.clear();
          imeiNoController.clear();
          priceController.clear();
          remarkController.clear();
          // Bill and Invoice numbers are already updated with next numbers
        });
      }

      // Navigate to SalalaBillPage
      try {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalalaBillPage(
                customerName: billingData['customerName'],
                customerAddress: billingData['customerAddress'],
                customerPhoneNumber: billingData['customerPhoneNumber'],
                billNo: finalBillNo,
                invoiceNo: finalInvoiceNo,
                headphoneModel: billingData['headphoneModel'],
                date: billingData['date'],
                imeiNo: billingData['imeiNo'],
                totalPrice: totalPrice,
                taxableAmount: taxableAmount,
                cgst: cgst,
                sgst: sgst,
                amountInWords: amountInWords,
              ),
            ),
          );
        }
      } catch (e) {
        print('Navigation error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation error: $e')),
          );
        }
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving to database. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
                    readOnly: !_isNumberGenerationFailed, // Make read-only unless generation failed
                  ),
                  _buildTextField(
                    label: 'Invoice Number',
                    icon: Icons.description,
                    controller: invoiceNoController,
                    readOnly: !_isNumberGenerationFailed, // Make read-only unless generation failed
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
                  
                  /// REMARK TEXT AREA
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Remark (Optional)',
                        hintText: 'Enter any additional notes or remarks...',
                        prefixIcon: Icon(Icons.note_add, color: Theme.of(context).colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      // No validator since it's optional
                    ),
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








