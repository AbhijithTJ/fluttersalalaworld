import 'package:flutter/material.dart';

class SalalaBillPage extends StatelessWidget {
  const SalalaBillPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Logo and Design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.blue[200]!],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Salala World",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    "MOBILE SALES & REPAIR",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Shop and Customer Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoColumn("SHOP Address", [
                  "Near Supplyco,",
                  "Meenangadi, 673591",
                ]),
                _infoColumn("SHOP PHONE", [
                  "8147668045",
                  "7901753565",
                ]),
                _infoColumn("HEADPHONE MODEL", ["-"]),
              ],
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoColumn("Customer Address", ["-", "-", "-"]),
                _infoColumn("Bill No", ["Raherose@gmail.com"]),
                _infoColumn("Invoice No", ["-"]),
                _infoColumn("Date", ["-"]),
              ],
            ),

            const SizedBox(height: 12),

            // Table Header
            Table(
              border: TableBorder.all(color: Colors.teal),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(),
                6: FlexColumnWidth(),
              },
              children: [
                _tableRow(
                  ['Sl. NO', 'Item', 'Unit price', 'Discount', 'CGST Amt', 'SGST Amt', 'Total'],
                  isHeader: true,
                ),
                for (int i = 1; i <= 6; i++)
                  _tableRow([i.toString(), '', '', '', '', '', '']),
                _tableRow(['', '', '', 'Total', '', '', '']),
              ],
            ),

            const SizedBox(height: 16),

            // Grand Total Section
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Grand Total in words:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "NINE THOUSAND NINE HUNDRED NINETY-NINE",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text("For: - Salala world"),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Authorized Signatory",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Text("Thanks you. Visit again."),
          ],
        ),
      ),
    );
  }

  // Helper to create Info Sections
  Widget _infoColumn(String title, List<String> lines) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("➤ [$title]:",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ...lines.map((e) => Text(e)),
          ],
        ),
      ),
    );
  }

  // Helper to create Table Rows
  TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.teal : Colors.white),
      children: cells
          .map(
            (e) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            e,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? Colors.white : Colors.black87,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
