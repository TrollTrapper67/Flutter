import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanApplicationsPage extends StatelessWidget {
  const LoanApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loan Applications")),
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
      BuildContext context, DocumentReference ref, String newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == "approved" ? "Approve Loan" : "Deny Loan"),
        content: Text(
            "Are you sure you want to ${newStatus == "approved" ? "approve" : "deny"} this application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.update({"status": newStatus});
              Navigator.of(ctx).pop();
            },
            child: Text(newStatus == "approved" ? "Approve" : "Deny"),
          ),
        ],
      ),
    );
  }
}
