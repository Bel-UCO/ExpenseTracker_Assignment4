import 'user_model.dart';

class UserWithTotal {
  final UserModel user;
  final double income;
  final double expense;

  UserWithTotal({
    required this.user,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}
