import 'package:cloud_firestore/cloud_firestore.dart';

class NumberGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> incrementAndGetNextNumber(String type) async {
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

  Future<int> peekNextNumber(String type) async {
    final DocumentSnapshot snapshot = await _firestore.collection('counters').doc(type).get();
    if (snapshot.exists) {
      return snapshot.get('current_value') ?? 0;
    }
    return 0;
  }
}