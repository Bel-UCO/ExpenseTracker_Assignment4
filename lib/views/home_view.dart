import 'package:flutter/material.dart';
import '../db/transaction_database.dart';
import '../models/user_model.dart';
import 'transaction_list_view.dart';
import 'category_view.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add User'),
        content: Text('Are you sure you want to add "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TransactionDatabase.instance.createUser(UserModel(name: name));
      _controller.clear();
      _loadUsers();
    }
  }

  void _editUserDialog(UserModel user) {
    final editController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit User'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                final updatedUser = UserModel(id: user.id, name: newName);
                await TransactionDatabase.instance.updateUser(updatedUser);
                Navigator.pop(context);
                _loadUsers();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TransactionDatabase.instance.deleteUser(id);
      _loadUsers();
    }
  }

  Future<Map<String, double>> _getSummary(int userId) async {
    return await TransactionDatabase.instance.getSummaryByUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: Text('Users & Balance'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryView()),
              );
            },
          ),
        ],
      ),
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
                            final balance = income - expense;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior:
                                    Clip.antiAlias, // agar radius clip
                                child: Slidable(
                                  key: ValueKey(user.id),
                                  endActionPane: ActionPane(
                                    motion:
                                        const DrawerMotion(), // atau const StretchMotion()
                                    extentRatio:
                                        0.5, // Total lebar action (0.5 = 50% of tile)
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _editUserDialog(user),
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Edit',
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      SlidableAction(
                                        onPressed: (_) => _deleteUser(user.id!),
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'Delete',
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    title: Text(user.name),
                                    subtitle: Text(
                                      'Balance: ${currencyFormatter.format(balance)}',
                                      style: TextStyle(
                                        color: balance >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing:
                                        Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TransactionListView(
                                              userId: user.id!),
                                        ),
                                      ).then((_) => _loadUsers());
                                    },
                                  ),
                                ),
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
