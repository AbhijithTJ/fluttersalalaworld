import 'package:flutter/material.dart';

class AlertBox {
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners
          backgroundColor: Colors.white, // Explicitly white background
          elevation: 10, // Add some shadow
          title: Column( // Use a Column for title and icon
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange, size: 40), // Warning icon
              SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content, textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: <Widget>[
            Row( // Use Row to space out buttons
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton( // "No" button
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey), // Text and border color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton( // "Yes" button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Background color
                    foregroundColor: Colors.white, // Text color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 5,
                  ),
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
