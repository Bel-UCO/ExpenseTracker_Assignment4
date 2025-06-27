import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../views/add_transaction_view.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../db/transaction_database.dart';

class TransactionListView extends StatefulWidget {
  final int userId;

  const TransactionListView({Key? key, required this.userId}) : super(key: key);

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  DateTime selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await TransactionDatabase.instance.readAllCategories();
    setState(() => _categories = cats);

    await Provider.of<TransactionViewModel>(context, listen: false)
        .fetchTransactionsByUser(widget.userId);

    Provider.of<TransactionViewModel>(context, listen: false)
        .filterByMonthYear(selectedDate.month, selectedDate.year);
  }

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month and Year',
      fieldHintText: 'MM/YYYY',
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      Provider.of<TransactionViewModel>(context, listen: false)
          .filterByMonthYear(picked.month, picked.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TransactionViewModel>(context);
    final transactions = viewModel.transactions;

    final incomeTotal = transactions
        .where((e) => e.type == 'Income')
        .fold(0.0, (sum, e) => sum + e.amount);
    final expenseTotal = transactions
        .where((e) => e.type == 'Expense')
        .fold(0.0, (sum, e) => sum + e.amount);
    final balance = incomeTotal - expenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions - ${DateFormat('MMMM yyyy').format(selectedDate)}',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          SummaryCard(
            income: incomeTotal,
            expense: expenseTotal,
            balance: balance,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                suffixIcon: Icon(Icons.filter_list),
              ),
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map((cat) => DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.name),
                    )),
              ],
              onChanged: (val) {
                setState(() => _selectedCategoryId = val);
                Provider.of<TransactionViewModel>(context, listen: false)
                    .filterByCategory(val);
              },
            ),
          ),
          SizedBox(height: 8),
          Divider(),
          Expanded(
            child: transactions.isEmpty
                ? Center(child: Text("No transactions for this month."))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (_, i) {
                      final txn = transactions[i];
                      return ListTile(
                        leading: Icon(
                          txn.type == 'Income'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color:
                              txn.type == 'Income' ? Colors.green : Colors.red,
                        ),
                        title: Text(
                            '${txn.type}: ${txn.amount.toStringAsFixed(0)}'),
                        subtitle:
                            Text(DateFormat('dd MMM yyyy').format(txn.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionView(
                                      userId: widget.userId,
                                      existingTransaction: txn,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Transaction'),
                                    content: Text(
                                        'Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                      ),
                                      TextButton(
                                        child: Text('Delete'),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await Provider.of<TransactionViewModel>(
                                          context,
                                          listen: false)
                                      .deleteTransaction(txn.id!);
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionView(userId: widget.userId),
            ),
          ).then((_) => _loadData());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SummaryRow(label: 'Income', value: income, color: Colors.green),
            SummaryRow(label: 'Expense', value: expense, color: Colors.red),
            Divider(),
            SummaryRow(label: 'Balance', value: balance, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
