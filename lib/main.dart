import 'package:flutter/material.dart';
import 'views/home_view.dart';
import 'package:provider/provider.dart';
import 'viewmodels/transaction_viewmodel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionViewModel(),
      child: MaterialApp(
        title: 'Money Manager',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark, // 🔥 Aktifkan dark mode
        theme: ThemeData.light(), // (opsional, bisa kosong)
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardColor: Colors.grey[850],
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.white70),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
          iconTheme: IconThemeData(color: Colors.white70),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.indigo,
          ),
        ),
        home: HomeView(),
      ),
    );
  }
}
