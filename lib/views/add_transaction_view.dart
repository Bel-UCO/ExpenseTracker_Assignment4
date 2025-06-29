import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../db/transaction_database.dart';
import '../viewmodels/transaction_viewmodel.dart';

class AddTransactionView extends StatefulWidget {
  final int userId;
  final TransactionModel? existingTransaction;

  const AddTransactionView({
    Key? key,
    required this.userId,
    this.existingTransaction,
  }) : super(key: key);

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Income';
  double _amount = 0;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.existingTransaction != null) {
      final txn = widget.existingTransaction!;
      _type = txn.type;
      _amount = txn.amount;
      _selectedCategoryId = txn.categoryId;
      _selectedDate = txn.date;
    }
  }

  Future<void> _loadCategories() async {
    final cats = await TransactionDatabase.instance.readAllCategories();
    setState(() {
      _categories = cats;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    _formKey.currentState!.save();

    final txn = TransactionModel(
      type: _type,
      amount: _amount,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      userId: widget.userId,
    );

    await Provider.of<TransactionViewModel>(context, listen: false)
        .addTransaction(txn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: ['Income', 'Expense'].map((val) {
                  return DropdownMenuItem(value: val, child: Text(val));
                }).toList(),
                onChanged: (val) => setState(() => _type = val!),
                decoration: InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                decoration: InputDecoration(labelText: 'Category'),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  ),
                  Spacer(),
                  ElevatedButton(
                    child: Text("Select"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              Spacer(),
              ElevatedButton(
                child: Text("Save"),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
