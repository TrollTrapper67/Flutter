import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      ),
      // Add a drawer for user navigation
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.primaryColor),
              child: Text(
                'User Menu',
                style: textStyle.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to Settings Page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<String>(
        future: _getDisplayName(),
        builder: (context, snapshot) {
          final displayName = snapshot.data ?? fallbackName;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
<<<<<<< Updated upstream
                Row(
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Text(
                      'Welcome, $displayName',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
=======
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
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
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
                          Navigator.pushReplacementNamed(
                            context,
                            '/userloan',
                          ); // ← Changed to pushReplacement
                        },
                      ),
                      _buildActionCard(
                        Icons.payment,
                        'Make Payment',
                        Colors.green,
                        () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/userpayment',
                          ); // ← Changed to pushReplacement
                        },
                      ),
                      _buildActionCard(
                        Icons.history,
                        'View History',
                        Colors.orange,
                        () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/userhistory',
                          ); // ← Changed to pushReplacement
                        },
                      ),
                      _buildActionCard(
                        Icons.account_balance_wallet,
                        'My Loans',
                        Colors.purple,
                        () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/userLoanStatus',
                          ); // ← Changed to pushReplacement
                        },
                      ),
                    ],
                  ),
>>>>>>> Stashed changes
                ),
                const SizedBox(height: 20),
                _buildActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

<<<<<<< Updated upstream
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
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionCard(Icons.account_balance, 'Loan', () {
          Navigator.pushNamed(context, '/userloan');
        }),
        const SizedBox(width: 8),
        _actionCard(Icons.payment, 'Pay', () {
          Navigator.pushNamed(context, '/userpayment');
        }),
        const SizedBox(width: 8),
        _actionCard(Icons.history, 'View History', () {
          Navigator.pushNamed(context, '/userhistory');
        }),
        const SizedBox(width: 8),
        _actionCard(Icons.account_balance_wallet, 'My Loan', () {
          Navigator.pushNamed(context, '/userloanstatus');
        }),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
=======
  Widget _buildActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}
