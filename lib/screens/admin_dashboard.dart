import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Helper method to calculate total revenue from approved loans
  double _calculateRevenue(List<QueryDocumentSnapshot> approvedLoans) {
    double total = 0.0;
    for (var loan in approvedLoans) {
      final data = loan.data() as Map<String, dynamic>;
      final principal = data['principal'] ?? 0.0;
      if (principal is num) {
        total += principal.toDouble();
      }
    }
    return total;
  }

  // Helper method to format currency
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '₱${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₱${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return '₱${amount.toStringAsFixed(0)}';
    }
  }

  // Logout confirmation dialog
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

  // Firebase help dialog
  void _showFirebaseHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Firebase Setup Help"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "To fix this issue, you need to:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text("1. Create test data:"),
              Text("   • Sign up as a user first"),
              Text("   • Submit a loan application"),
              SizedBox(height: 8),
              Text("2. Check Firestore Rules:"),
              Text("   • Go to Firebase Console"),
              Text("   • Navigate to Firestore Database"),
              Text("   • Check Rules tab"),
              SizedBox(height: 8),
              Text("3. Verify Collections:"),
              Text("   • 'users' collection should exist"),
              Text("   • 'loan_applications' collection should exist"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Got it"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _initializeTestData(context);
            },
            child: const Text("Create Test Data"),
          ),
        ],
      ),
    );
  }

  // Initialize test data for development
  void _initializeTestData(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create a test user document
      await firestore.collection('users').doc('test-user').set({
        'email': 'test@example.com',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create test loan applications
      await firestore.collection('loan_applications').add({
        'userId': 'test-user',
        'email': 'test@example.com',
        'principal': 50000.0,
        'months': 12,
        'monthlyPayment': 4166.67,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('loan_applications').add({
        'userId': 'test-user',
        'email': 'test@example.com',
        'principal': 75000.0,
        'months': 24,
        'monthlyPayment': 3125.0,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test data created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a consistent theme for the dashboard
    final theme = Theme.of(context);
    final textStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      // Add a drawer for scalable navigation
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.primaryColor),
              child: Text(
                'Admin Menu',
                style: textStyle.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('User Management'),
              onTap: () {
                // Navigate to User Management Page
                Navigator.pop(context);
              },
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh by rebuilding the widget
          // The StreamBuilder will automatically update
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<QuerySnapshot>>(
          stream: _getCombinedStreams(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading dashboard data...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading dashboard data',
                        style: textStyle.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: textStyle.bodySmall?.copyWith(
                            color: Colors.red[800],
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Possible causes:\n• Firebase collections don\'t exist yet\n• Firestore rules are blocking access\n• Network connection issues',
                        style: textStyle.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Trigger a rebuild to retry
                              (context as Element).markNeedsBuild();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showFirebaseHelp(context),
                            icon: const Icon(Icons.help),
                            label: const Text('Help'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.length < 2) {
              return const Center(child: CircularProgressIndicator());
            }

            final loansSnapshot = snapshot.data![0];
            final usersSnapshot = snapshot.data![1];

            // Calculate statistics
            final allLoans = loansSnapshot.docs;
            final pendingLoans = allLoans.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? 'pending') == 'pending';
            }).toList();

            final approvedLoans = allLoans.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['status'] ?? 'pending') == 'approved';
            }).toList();

            final totalUsers = usersSnapshot.docs.length;
            final revenue = _calculateRevenue(approvedLoans);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin! 👋',
                    style: textStyle.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is a summary of the system status.',
                    style: textStyle.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Use a GridView for key statistics cards
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        icon: Icons.pending_actions,
                        label: 'Pending Loans',
                        value: '${pendingLoans.length}',
                        color: Colors.orange,
                      ),
                      StatCard(
                        icon: Icons.check_circle,
                        label: 'Approved Loans',
                        value: '${approvedLoans.length}',
                        color: Colors.green,
                      ),
                      StatCard(
                        icon: Icons.people,
                        label: 'Total Users',
                        value: '$totalUsers',
                        color: Colors.blue,
                      ),
                      StatCard(
                        icon: Icons.attach_money,
                        label: 'Total Revenue',
                        value: _formatCurrency(revenue),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: textStyle.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons using ListTile inside a Card for better UI
                  Card(
                    elevation: 6.0,
                    shadowColor: Colors.grey.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ActionTile(
                          icon: Icons.assignment,
                          title: 'Check Loan Applications',
                          subtitle: 'Review and approve new requests',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/LoanApplicationsPage',
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey[300],
                          thickness: 0.5,
                        ),
                        ActionTile(
                          icon: Icons.bar_chart,
                          title: 'View Reports',
                          subtitle: 'See analytics and performance data',
                          color: Colors.green,
                          onTap: () {
                            // Navigate to reports page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reports feature coming soon!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
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
      ),
    );
  }

  // Combine multiple Firestore streams
  Stream<List<QuerySnapshot>> _getCombinedStreams() async* {
    await for (final loansSnapshot
        in FirebaseFirestore.instance
            .collection('loan_applications')
            .snapshots()) {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      yield [loansSnapshot, usersSnapshot];
    }
  }
}

// Reusable widget for statistics cards
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable widget for action list tiles
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withValues(alpha: 0.05), Colors.transparent],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.chevron_right, color: color, size: 20),
        ),
        onTap: onTap,
      ),
    );
  }
}
