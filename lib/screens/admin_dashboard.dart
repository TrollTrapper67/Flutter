import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_project_final/screens/loanapplications.dart';
import './user_management.dart';

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

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '₱${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₱${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return '₱${amount.toStringAsFixed(0)}';
    }
  }

  Future<void> _createTestData(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': 'Test User',
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
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const LoanApplicationsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Admin Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/adminSettings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Admin History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/adminHistory');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
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
          stream: FirebaseFirestore.instance
              .collection('loan_applications')
              .snapshots(),
          builder: (context, loansSnapshot) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, usersSnapshot) {
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
                                onPressed: () => _createTestData(context),
                                icon: const Icon(Icons.help),
                                label: const Text('Create Test Data'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

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
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.green,
                                  ),
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
                              _buildStatusItem(
                                'Total Loans',
                                allLoans.length.toString(),
                                Icons.list_alt,
                              ),
                              _buildStatusItem(
                                'Pending Review',
                                pendingLoans.length.toString(),
                                Icons.pending,
                              ),
                              _buildStatusItem(
                                'Approved',
                                approvedLoans.length.toString(),
                                Icons.verified,
                              ),
                              _buildStatusItem(
                                'Rejected',
                                rejectedLoans.length.toString(),
                                Icons.cancel,
                              ),
                            ],
                          ),
                        ),
                      ),
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

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
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
