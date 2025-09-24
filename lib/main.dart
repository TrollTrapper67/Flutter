import 'package:flutter/material.dart';
import 'package:prototype_1/auth/login.dart';
import 'package:prototype_1/auth/signup.dart';
import 'package:prototype_1/screens/home.dart';
import 'package:prototype_1/screens/history.dart';
import 'package:prototype_1/screens/payment.dart';
import 'package:prototype_1/screens/loan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prototype 1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final username = (args is String) ? args : '[username]';
          return HomeScreen(username: username);
        },
        '/payment': (context) => const PaymentScreen(),
        '/loan': (context) => const LoanScreen(),
        '/history': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is List<HistoryItem>) {
            return HistoryScreen(items: args);
          }
          return const HistoryScreen();
        },
      },
    );
  }
}
