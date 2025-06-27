import 'package:flutter/material.dart';
import '../db/transaction_database.dart';
import '../models/user_model.dart';
import 'transaction_list_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<UserModel> _users = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await TransactionDatabase.instance.readAllUsers();
    setState(() => _users = users);
  }

  Future<void> _addUser() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await TransactionDatabase.instance.createUser(UserModel(name: name));
    _controller.clear();
    _loadUsers();
  }

  Future<Map<String, double>> _getSummary(int userId) async {
    return await TransactionDatabase.instance.getSummaryByUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users & Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New User Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addUser,
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _users.isEmpty
                  ? Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final user = _users[i];
                        return FutureBuilder<Map<String, double>>(
                          future: _getSummary(user.id!),
                          builder: (context, snapshot) {
                            final income = snapshot.data?['income'] ?? 0.0;
                            final expense = snapshot.data?['expense'] ?? 0.0;

                            return Card(
                              child: ListTile(
                                title: Text(user.name),
                                subtitle: Row(
                                  children: [
                                    Text('Income: ${income.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.green)),
                                    SizedBox(width: 16),
                                    Text(
                                        'Expense: ${expense.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionListView(
                                        userId: user.id!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
