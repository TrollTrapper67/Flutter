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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
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
                Row(
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Text(
                      'Welcome, $displayName',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildActions(context),
                const SizedBox(height: 20),
                _buildHistorySection(context),
                const SizedBox(height: 8),
                Expanded(child: _buildRecentActivityList()),
              ],
            ),
          );
        },
      ),
    );
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
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/userhistory'),
          child: const Text('See all'),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.payments)),
          title: const Text('No activity yet.'),
          subtitle: const SizedBox(height: 6),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
