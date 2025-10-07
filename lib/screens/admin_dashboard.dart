import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project_final/screens/loanapplications.dart';
import './user_management.dart';
import './admin_history.dart';
import './admin_messages.dart'; // Add this import

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
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test user created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        actions: [
          // Message Icon Button
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Send Payment Reminders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminMessagesPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // This will trigger the StreamBuilder to refresh
              (context as Element).markNeedsBuild();
            },
            tooltip: 'Refresh Data',
          ),
        ],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Loan Applications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoanApplicationsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Admin History'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Admin History Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminHistoryPage()),
                );
              },
            ),
            const Divider(),
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
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<QuerySnapshot>(
          // Use a simpler stream for loan applications only
          stream: FirebaseFirestore.instance
              .collection('loan_applications')
              .snapshots(),
          builder: (context, loansSnapshot) {
            // Use FutureBuilder for users since it doesn't change as frequently
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, usersSnapshot) {
                // Combined loading state
                if (loansSnapshot.connectionState == ConnectionState.waiting ||
                    usersSnapshot.connectionState == ConnectionState.waiting) {
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

                // Combined error state
                if (loansSnapshot.hasError || usersSnapshot.hasError) {
                  final error = loansSnapshot.error ?? usersSnapshot.error;
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
                              'Error: $error',
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

                // Check if data exists
                if (!loansSnapshot.hasData || !usersSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLoans = loansSnapshot.data!.docs;
                final allUsers = usersSnapshot.data!.docs;

                // Calculate statistics
                final pendingLoans = allLoans.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'pending') == 'pending';
                }).toList();

                final approvedLoans = allLoans.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'pending') == 'approved';
                }).toList();

                final rejectedLoans = allLoans.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'pending') == 'rejected';
                }).toList();

                final totalUsers = allUsers.length;
                final revenue = _calculateRevenue(approvedLoans);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live updates enabled',
                                    style: textStyle.bodySmall?.copyWith(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Statistics Grid
                      Text(
                        'Live Overview',
                        style: textStyle.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
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
                      
                      // System Status
                      Text(
                        'System Status',
                        style: textStyle.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusItem('Total Loans', allLoans.length.toString(), Icons.list_alt),
                              _buildStatusItem('Pending Review', pendingLoans.length.toString(), Icons.pending),
                              _buildStatusItem('Approved', approvedLoans.length.toString(), Icons.verified),
                              _buildStatusItem('Rejected', rejectedLoans.length.toString(), Icons.cancel),
                            ],
                          ),
                        ),
                      ),
                      // Quick Actions section and cards have been removed
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
      elevation: 4.0,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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