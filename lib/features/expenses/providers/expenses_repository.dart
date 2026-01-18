import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(FirebaseFirestore.instance);
});

class ExpensesRepository {
  final FirebaseFirestore _firestore;

  ExpensesRepository(this._firestore);

  Stream<List<ExpenseModel>> watchExpenses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }
}
