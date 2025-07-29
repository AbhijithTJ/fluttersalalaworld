import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wetherapp/salalabillui.dart';

class EditBillPage extends StatefulWidget {
  final Map<String, dynamic> billData;

  const EditBillPage({Key? key, required this.billData}) : super(key: key);

  @override
  State<EditBillPage> createState() => _EditBillPageState();
}

class _EditBillPageState extends State<EditBillPage> {
  final _formKey = GlobalKey<FormState>();

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
    _populateFields();
  }

  void _populateFields() {
    customerNameController.text = widget.billData['customerName'] ?? '';
    customerAddressController.text = widget.billData['customerAddress'] ?? '';
    customerPhoneNumberController.text = widget.billData['customerPhoneNumber'] ?? '';
    billNoController.text = widget.billData['billNo']?.toString() ?? '';
    headphoneModelController.text = widget.billData['headphoneModel'] ?? '';
    dateController.text = widget.billData['date'] ?? '';
    invoiceNoController.text = widget.billData['invoiceNo'] ?? '';
    imeiNoController.text = widget.billData['imeiNo'] ?? '';
    priceController.text = widget.billData['totalPrice']?.toString() ?? '';
    remarkController.text = widget.billData['remark'] ?? '';
  }

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

  Future<void> _updateForm() async {
    if (_formKey.currentState!.validate()) {
      double totalPrice = double.tryParse(priceController.text) ?? 0;
      double taxableAmount = totalPrice / 1.18;
      double cgst = taxableAmount * 0.09;
      double sgst = taxableAmount * 0.09;
      String amountInWords = convertNumberToWords(totalPrice.round());

      Map<String, dynamic> updatedData = {
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
        'remark': remarkController.text,
      };

      try {
        await FirebaseFirestore.instance
            .collection('bills')
            .doc(widget.billData['id'])
            .update(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill updated successfully')),
        );
        Navigator.pop(context); // Pop the edit page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalalaBillPage(
              customerName: updatedData['customerName'],
              customerAddress: updatedData['customerAddress'],
              customerPhoneNumber: updatedData['customerPhoneNumber'],
              billNo: updatedData['billNo'],
              invoiceNo: updatedData['invoiceNo'],
              headphoneModel: updatedData['headphoneModel'],
              date: updatedData['date'],
              imeiNo: updatedData['imeiNo'],
              totalPrice: updatedData['totalPrice'],
              taxableAmount: updatedData['taxableAmount'],
              cgst: updatedData['cgst'],
              sgst: updatedData['sgst'],
              amountInWords: updatedData['amountInWords'],
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating bill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: 'Customer Name',
                controller: customerNameController,
              ),
              _buildTextField(
                label: 'Customer Address',
                controller: customerAddressController,
              ),
              _buildTextField(
                label: 'Customer Phone Number',
                controller: customerPhoneNumberController,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: 'Bill No',
                controller: billNoController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'Invoice Number',
                controller: invoiceNoController,
              ),
              _buildTextField(
                label: 'Headphone Model',
                controller: headphoneModelController,
              ),
              _buildTextField(
                label: 'Date',
                controller: dateController,
              ),
              _buildTextField(
                label: 'IMEI Number',
                controller: imeiNoController,
              ),
              _buildTextField(
                label: 'Price',
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                label: 'Remark',
                controller: remarkController,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateForm,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
