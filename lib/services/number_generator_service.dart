import 'package:cloud_firestore/cloud_firestore.dart';

class NumberGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getNextNumber(String type) async {
    final DocumentReference counterRef = _firestore.collection('counters').doc(type);

    return _firestore.runTransaction((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(counterRef);

      int currentNumber = 0;
      if (snapshot.exists) {
        currentNumber = snapshot.get('current_value') ?? 0;
      }

      int nextNumber = currentNumber + 1;
      transaction.set(counterRef, {'current_value': nextNumber});
      return nextNumber;
    });
  }
}