import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanApplicationsPage extends StatelessWidget {
  const LoanApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Applications"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/adminDashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clean_hands),
            tooltip: 'Clean Duplicate Loans',
            onPressed: () => _showCleanDuplicatesDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All Applications',
            onPressed: () => _showClearApplicationsDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("loan_applications")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No loan applications found."));
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final data = app.data() as Map<String, dynamic>;

              final status = data['status'] ?? "pending";
              final Color statusColor;
              switch (status) {
                case "approved":
                  statusColor = Colors.green;
                  break;
                case "denied":
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.account_circle, size: 40),
                  title: Text("User: ${data['email'] ?? 'Unknown'}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Principal: ₱${data['principal']}"),
                      Text("Months: ${data['months']}"),
                      Text("Monthly Payment: ₱${data['monthlyPayment']}"),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: "Approve",
                        onPressed: () {
                          _confirmAction(context, app.reference, "approved");
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: "Deny",
                        onPressed: () {
                          _confirmAction(context, app.reference, "denied");
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    DocumentReference ref,
    String newStatus,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == "approved" ? "Approve Loan" : "Deny Loan"),
        content: Text(
          "Are you sure you want to ${newStatus == "approved" ? "approve" : "deny"} this application?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update the loan application status
              await ref.update({"status": newStatus});

              // Get the application data for logging
              final appData = await ref.get();
              final data = appData.data() as Map<String, dynamic>;

              // Create admin log entry
              await FirebaseFirestore.instance.collection("admin_logs").add({
                "action": newStatus,
                "userEmail": data['email'] ?? 'Unknown',
                "principal": data['principal'] ?? 0.0,
                "months": data['months'] ?? 0,
                "monthlyPayment": data['monthlyPayment'] ?? 0.0,
                "timestamp": FieldValue.serverTimestamp(),
                "applicationId": ref.id,
              });

              // If approved, create user loan record (only if no active loan exists)
              if (newStatus == "approved") {
                // Check if user already has an active loan
                final existingLoanQuery = await FirebaseFirestore.instance
                    .collection("user_loans")
                    .where('userId', isEqualTo: data['userId'] ?? '')
                    .where('status', isEqualTo: 'active')
                    .get();

                if (existingLoanQuery.docs.isEmpty) {
                  // No active loan exists, create new one
                  await FirebaseFirestore.instance
                      .collection("user_loans")
                      .add({
                        "userId": data['userId'] ?? '',
                        "userEmail": data['email'] ?? 'Unknown',
                        "principal": data['principal'] ?? 0.0,
                        "remainingBalance": data['principal'] ?? 0.0,
                        "months": data['months'] ?? 0,
                        "monthlyPayment": data['monthlyPayment'] ?? 0.0,
                        "status": "active",
                        "approvedAt": FieldValue.serverTimestamp(),
                        "applicationId": ref.id,
                      });
                } else {
                  // User already has an active loan, show warning
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚠️ User already has an active loan. Cannot approve another.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                  return; // Don't update the application status
                }
              }

              Navigator.of(ctx).pop();

              // Show success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Application ${newStatus == "approved" ? "approved" : "rejected"} successfully',
                    ),
                    backgroundColor: newStatus == "approved"
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            child: Text(newStatus == "approved" ? "Approve" : "Deny"),
          ),
        ],
      ),
    );
  }

  void _showClearApplicationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Applications'),
        content: const Text(
          'Are you sure you want to delete all loan applications?\n\n'
          'This action cannot be undone. All loan applications will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearAllApplications(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Applications'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllApplications(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Clearing applications...'),
            ],
          ),
        ),
      );

      // Get all documents in loan_applications collection
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('loan_applications')
          .get();

      // Delete all documents in batches
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All loan applications cleared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing applications: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showCleanDuplicatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clean Duplicate Loans'),
        content: const Text(
          'This will keep only the most recent active loan for each user and remove older duplicates.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cleanDuplicateLoans(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clean Duplicates'),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanDuplicateLoans(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Cleaning duplicate loans...'),
            ],
          ),
        ),
      );

      // Get all active loans
      final allLoansQuery = await FirebaseFirestore.instance
          .collection('user_loans')
          .where('status', isEqualTo: 'active')
          .get();

      // Group loans by userId
      final Map<String, List<QueryDocumentSnapshot>> loansByUser = {};
      for (var doc in allLoansQuery.docs) {
        final userId = doc.data()['userId'] as String? ?? '';
        if (!loansByUser.containsKey(userId)) {
          loansByUser[userId] = [];
        }
        loansByUser[userId]!.add(doc);
      }

      // For each user, keep only the most recent loan and mark others as inactive
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      int duplicatesRemoved = 0;

      for (var userId in loansByUser.keys) {
        final userLoans = loansByUser[userId]!;
        if (userLoans.length > 1) {
          // Sort by approvedAt timestamp (most recent first)
          userLoans.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData?['approvedAt'] as Timestamp?;
            final bTime = bData?['approvedAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Keep the first (most recent) loan, mark others as inactive
          for (int i = 1; i < userLoans.length; i++) {
            batch.update(userLoans[i].reference, {'status': 'inactive'});
            duplicatesRemoved++;
          }
        }
      }

      // Commit the batch
      await batch.commit();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Cleaned $duplicatesRemoved duplicate loans successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error cleaning duplicates: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
