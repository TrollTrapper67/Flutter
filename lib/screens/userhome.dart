// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project_final/screens/userloanstatus.dart';
import 'package:flutter_project_final/screens/userinfo.dart'; // Add this import

class HomeScreen extends StatelessWidget {
  final String? username;

  const HomeScreen({super.key, this.username});

  Future<String> _getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "Guest";
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey("name")) {
          return data["name"] ?? user.email ?? "Guest";
        }
      }
      return user.email ?? "Guest";
    } catch (e) {
      return user.email ?? "Guest";
    }
  }

  // 🔹 Confirmation Dialog for Logout
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // close dialog
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeArg = ModalRoute.of(context)?.settings.arguments;
    String? routeUsername;
    if (routeArg is String && routeArg.isNotEmpty) {
      routeUsername = routeArg;
    } else if (routeArg != null) {
      routeUsername = routeArg.toString();
    }

    final fallbackName = username ?? routeUsername ?? "Guest";
    final theme = Theme.of(context);
    final textStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        automaticallyImplyLeading: false, // ← This removes the back button
        leading: IconButton( // ← Added user icon on the left
          icon: const Icon(Icons.person),
          tooltip: 'User Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserInfoScreen()),
            );
          },
        ),
        actions: [          
          // Logout Icon Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _confirmLogout(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getDisplayName(),
        builder: (context, snapshot) {
          final displayName = snapshot.data ?? fallbackName;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Welcome Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome!',
                                style: textStyle.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                displayName,
                                style: textStyle.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Quick Actions Title
                Text(
                  'Quick Actions',
                  style: textStyle.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        Icons.account_balance,
                        'Apply for Loan',
                        Colors.blue,
                        () {
                          Navigator.pushReplacementNamed(context, '/userloan');
                        },
                      ),
                      _buildActionCard(
                        Icons.payment,
                        'Make Payment',
                        Colors.green,
                        () {
                          Navigator.pushReplacementNamed(context, '/userpayment');
                        },
                      ),
                      _buildActionCard(
                        Icons.history,
                        'View History',
                        Colors.orange,
                        () {
                          Navigator.pushReplacementNamed(context, '/userhistory');
                        },
                      ),
                      _buildActionCard(
                        Icons.account_balance_wallet,
                        'My Loans',
                        Colors.purple,
                        () {
                          Navigator.pushReplacementNamed(context, '/userLoanStatus');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}