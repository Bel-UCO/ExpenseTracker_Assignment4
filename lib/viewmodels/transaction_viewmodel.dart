import 'package:flutter/material.dart';
import '../db/transaction_database.dart';
import '../models/transaction_model.dart';

class TransactionViewModel extends ChangeNotifier {
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> transactions = [];

  int currentUserId = 0;
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  int? selectedCategoryId;

  // Tambahkan transaksi baru
  Future<void> addTransaction(TransactionModel txn) async {
    await TransactionDatabase.instance.createTransaction(txn);
    await fetchTransactionsByUser(txn.userId); // refresh otomatis
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    await TransactionDatabase.instance.updateTransaction(txn);
    await fetchTransactionsByUser(txn.userId);
    filterByMonthYear(txn.date.month, txn.date.year);
  }

  Future<void> deleteTransaction(int id) async {
    await TransactionDatabase.instance.deleteTransaction(id);
    await fetchTransactionsByUser(
        currentUserId); // pastikan currentUserId disimpan
    filterByMonthYear(currentMonth, currentYear);
  }

  // Ambil transaksi berdasarkan user (semua bulan)
  Future<void> fetchTransactionsByUser(int userId) async {
    currentUserId = userId; // ⬅️ Simpan
    final data =
        await TransactionDatabase.instance.readTransactionsByUser(userId);
    _allTransactions = data;
    notifyListeners();
  }

  // Ambil transaksi berdasarkan user, bulan, dan tahun
  void filterByMonthYear(int month, int year) {
    currentMonth = month;
    currentYear = year;

    transactions = _allTransactions.where((txn) {
      final matchDate = txn.date.month == month && txn.date.year == year;
      final matchCategory =
          selectedCategoryId == null || txn.categoryId == selectedCategoryId;
      return matchDate && matchCategory;
    }).toList();

    notifyListeners();
  }

  void filterByCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    filterByMonthYear(
        currentMonth, currentYear); // Refilter pakai kategori baru
  }

  // (Opsional) Reset filter
  Future<void> resetFilter(int userId) async {
    await fetchTransactionsByUser(userId);
  }
}
