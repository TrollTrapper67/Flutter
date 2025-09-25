// replace lib/main.dart with this if your widget classes are LoanPage / PaymentPage / HistoryPage
import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'auth/signup.dart';
import 'screens/home.dart';
import 'screens/loan.dart';
import 'screens/payment.dart';
import 'screens/history.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prototype 1',
      initialRoute: '/',
      routes: {
        '/': (ctx) => const LoginScreen(),      // if LoginScreen exists
        '/signup': (ctx) => const SignUpScreen(), // if SignUpScreen exists
        '/home': (ctx) => const HomeScreen(),   // if HomeScreen exists
        '/loan': (ctx) => const LoanPage(),
        '/payment': (ctx) => const PaymentPage(),
        '/history': (ctx) => const HistoryPage(),
      },
    );
  }
}
