// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              
              // Don't show cards that are already approved or denied
              if (status == "approved" || status == "denied") {
                return const SizedBox.shrink();
              }

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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name first
                      Text(
                        "Name: ${data['name'] ?? 'Unknown'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Email second
                      Text(
                        "Email: ${data['email'] ?? 'Unknown'}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text("Principal: ₱${data['principal']}"),
                      Text("Months: ${data['months']}"),
                      Text("Monthly Payment: ₱${data['monthlyPayment']}"),
                      const SizedBox(height: 4),
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
                      // Information Icon Button
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue),
                        tooltip: "View User Details",
                        onPressed: () {
                          _showUserDetails(context, data['userId'], data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: "Approve",
                        onPressed: () {
                          _confirmAction(context, app.reference, "approved", data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: "Decline",
                        onPressed: () {
                          _showDeclineReasonDialog(context, app.reference, data);
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

  // Show user details from Firestore
  void _showUserDetails(BuildContext context, String? userId, Map<String, dynamic> applicationData) async {
    if (userId == null || userId.isEmpty) {
      _showError(context, 'User ID not found');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading user details...'),
          ],
        ),
      ),
    );

    try {
      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Close loading dialog
      Navigator.of(context).pop();

      if (!userDoc.exists) {
        _showError(context, 'User data not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      
      // Show user details dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person, color: Colors.blue),
              SizedBox(width: 8),
              Text('User Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Personal Information
                _buildDetailRow('Name', userData?['name'] ?? 'Not provided'),
                _buildDetailRow('Email', applicationData['email'] ?? 'Not provided'),
                _buildDetailRow('Age', userData?['age']?.toString() ?? 'Not provided'),
                _buildDetailRow('Phone', userData?['phone'] ?? 'Not provided'),
                _buildDetailRow('Address', userData?['address'] ?? 'Not provided'),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Credibility Information
                const Text(
                  'Credibility Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildDetailRow('Credibility Score', 
                  userData?['credibilityScore']?.toString() ?? 'Not set'),
                
                // Credibility Factors
                if (userData?['credibilityFactors'] != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Credibility Factors:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  ..._buildCredibilityFactors(userData?['credibilityFactors']),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Loan Application Information
                const Text(
                  'Loan Application',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildDetailRow('Principal', '₱${applicationData['principal']}'),
                _buildDetailRow('Term', '${applicationData['months']} months'),
                _buildDetailRow('Monthly Payment', '₱${applicationData['monthlyPayment']}'),
                _buildDetailRow('Applied On', 
                  _formatTimestamp(applicationData['createdAt'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showError(context, 'Error loading user details: $e');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCredibilityFactors(Map<String, dynamic>? factors) {
    if (factors == null) return [const SizedBox()];
    
    final List<Widget> widgets = [];
    factors.forEach((key, value) {
      if (value is bool) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.cancel,
                  color: value ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCredibilityFactor(key),
                  style: TextStyle(
                    color: value ? Colors.green : Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (key == 'incomeRange') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Income Range: ${_formatIncomeRange(value)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
    });
    
    return widgets;
  }

  String _formatCredibilityFactor(String factor) {
    switch (factor) {
      case 'hasValidID':
        return 'Valid Government ID';
      case 'hasEmployment':
        return 'Stable Employment';
      case 'hasBankAccount':
        return 'Bank Account';
      case 'hasGoodCreditHistory':
        return 'Good Credit History';
      case 'hasCollateral':
        return 'Collateral Available';
      default:
        return factor;
    }
  }

  String _formatIncomeRange(int range) {
    switch (range) {
      case 0:
        return 'Less than ₱20,000';
      case 1:
        return '₱20,000 - ₱50,000';
      case 2:
        return '₱50,000 - ₱100,000';
      case 3:
        return 'More than ₱100,000';
      default:
        return 'Not specified';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }

  void _showUserCredibilityScreen(BuildContext context, String userId) {
    // Navigate to user credibility screen or show more details
    // You can implement this based on your app's navigation structure
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Full Profile'),
        content: const Text('This would navigate to the full user credibility profile screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    DocumentReference ref,
    String newStatus,
    Map<String, dynamic> applicationData,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == "approved" ? "Approve Loan" : "Decline Loan"),
        content: Text(
          "Are you sure you want to ${newStatus == "approved" ? "approve" : "decline"} this application?",
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
                "userName": data['name'] ?? 'Unknown',
                "userEmail": data['email'] ?? 'Unknown',
                "principal": data['principal'] ?? 0.0,
                "months": data['months'] ?? 0,
                "monthlyPayment": data['monthlyPayment'] ?? 0.0,
                "timestamp": FieldValue.serverTimestamp(),
                "applicationId": ref.id,
              });

              // Send notification to user
              final userId = data['userId'];
              final userName = data['name'] ?? 'Unknown';
              if (userId != null && userId.isNotEmpty) {
                if (newStatus == "approved") {
                  await sendNotification(
                    userId: userId,
                    title: 'Loan Application Approved! 🎉',
                    message: 'Congratulations $userName! Your loan application for ₱${data['principal']} has been approved.',
                    type: 'success',
                    action: 'view_loan',
                  );
                } else {
                  await sendNotification(
                    userId: userId,
                    title: 'Loan Application Update',
                    message: 'Your loan application for ₱${data['principal']} has been reviewed. Status: Declined.',
                    type: 'info',
                    action: 'apply_loan',
                  );
                }
              }

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
                        "userName": data['name'] ?? 'Unknown',
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
                      'Application ${newStatus == "approved" ? "approved" : "declined"} successfully',
                    ),
                    backgroundColor: newStatus == "approved"
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            child: Text(newStatus == "approved" ? "Approve" : "Decline"),
          ),
        ],
      ),
    );
  }

  // ... (rest of the methods remain the same: _showDeclineReasonDialog, _processDeclineApplication, _showClearApplicationsDialog, _clearAllApplications, _showCleanDuplicatesDialog, _cleanDuplicateLoans, sendNotification, sendNotificationToAll)

  void _showDeclineReasonDialog(BuildContext context, DocumentReference ref, Map<String, dynamic> applicationData) {
    String? selectedReason;
    String customReason = '';
    final TextEditingController customReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Decline Loan Application'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please select the reason for declining this loan application:'),
                  const SizedBox(height: 16),
                  
                  // Dropdown for decline reasons
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Select Reason',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Lacking of information',
                        child: Text('Lacking of information'),
                      ),
                      DropdownMenuItem(
                        value: 'Insufficient credibility score',
                        child: Text('Insufficient credibility score'),
                      ),
                      DropdownMenuItem(
                        value: 'Others',
                        child: Text('Others...'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom reason text field (only shown when "Others" is selected)
                  if (selectedReason == 'Others')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Please specify the reason:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: customReasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter specific reason for declining...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              customReason = value;
                            });
                          },
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Validation message
                  if (selectedReason == 'Others' && customReason.isEmpty)
                    const Text(
                      'Please provide a reason',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedReason != null && 
                           (selectedReason != 'Others' || customReason.isNotEmpty))
                    ? () async {
                        final declineReason = selectedReason == 'Others' 
                            ? customReason 
                            : selectedReason!;
                        
                        await _processDeclineApplication(
                          context, 
                          ref, 
                          applicationData, 
                          declineReason
                        );
                        Navigator.of(ctx).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Decline'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processDeclineApplication(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> applicationData,
    String declineReason,
  ) async {
    try {
      // Update the loan application status and add decline reason
      await ref.update({
        "status": "denied",
        "declineReason": declineReason,
        "declinedAt": FieldValue.serverTimestamp(),
      });

      // Get the application data for logging
      final appData = await ref.get();
      final data = appData.data() as Map<String, dynamic>;

      // Create admin log entry with decline reason
      await FirebaseFirestore.instance.collection("admin_logs").add({
        "action": "denied",
        "userName": data['name'] ?? 'Unknown',
        "userEmail": data['email'] ?? 'Unknown',
        "principal": data['principal'] ?? 0.0,
        "months": data['months'] ?? 0,
        "monthlyPayment": data['monthlyPayment'] ?? 0.0,
        "declineReason": declineReason,
        "timestamp": FieldValue.serverTimestamp(),
        "applicationId": ref.id,
      });

      // Send detailed notification to user with the specific reason
      final userId = data['userId'];
      final userName = data['name'] ?? 'Unknown';
      if (userId != null && userId.isNotEmpty) {
        await sendNotification(
          userId: userId,
          title: 'Loan Application Declined',
          message: 'Your loan application for ₱${data['principal']} has been declined. Reason: $declineReason',
          type: 'info',
          action: 'apply_loan',
        );
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application declined successfully. Reason: $declineReason'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

      // Send notification to affected users
      for (var userId in loansByUser.keys) {
        final userLoans = loansByUser[userId]!;
        if (userLoans.length > 1) {
          await sendNotification(
            userId: userId,
            title: 'Loan Account Updated',
            message: 'Your duplicate loan accounts have been consolidated. Only your most recent active loan remains.',
            type: 'info',
            action: 'view_loan',
          );
        }
      }

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

// Utility function to send notifications
Future<void> sendNotification({
  required String userId,
  required String title,
  required String message,
  String type = 'info',
  String action = '',
}) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'action': action,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error sending notification: $e');
  }
}

// Send notification to all users
Future<void> sendNotificationToAll({
  required String title,
  required String message,
  String type = 'info',
  String action = '',
}) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': 'all', // Special ID for all users
      'title': title,
      'message': message,
      'type': type,
      'action': action,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error sending notification to all: $e');
  }
}