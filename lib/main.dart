import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'auth/signup.dart';
import 'screens/home.dart';
import 'screens/history.dart';
import 'screens/payment.dart'; // <-- new

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
        '/payment': (context) => const PaymentScreen(), // <-- added
        '/history': (context) {
          // Accept a List<HistoryItem> through arguments when present.
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
