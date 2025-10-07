// lib/screens/userhistory.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEntry {
  final DateTime date;
  final double amount;
  final String operation;
  final String description;
  final String? loanId;
  final String? paymentMethod;
  final String? receiptId;
  final String? paymentId;

  HistoryEntry({
    required this.date,
    required this.amount,
    required this.operation,
    required this.description,
    this.loanId,
    this.paymentMethod,
    this.receiptId,
    this.paymentId,
  });
}

class UserHistoryPage extends StatefulWidget {
  static const routeName = '/userhistory';
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  final List<HistoryEntry> _allHistory = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
        _allHistory.clear();
      });

      // Fetch loan applications
      final loanApplications = await FirebaseFirestore.instance
          .collection('loan_applications')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Fetch payments
      final payments = await FirebaseFirestore.instance
          .collection('user_payments')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Fetch user loans
      final userLoans = await FirebaseFirestore.instance
          .collection('user_loans')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<HistoryEntry> history = [];

      // Add loan applications
      for (final doc in loanApplications.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          history.add(
            HistoryEntry(
              date: createdAt.toDate(),
              amount: (data['principal'] ?? 0.0).toDouble(),
              operation: 'Loan Application',
              description:
                  'Applied for ₱${_formatCurrency((data['principal'] ?? 0.0).toDouble())} loan',
              loanId: doc.id,
            ),
          );
        }
      }

      // Add loan approvals
      for (final doc in userLoans.docs) {
        final data = doc.data();
        final approvedAt = data['approvedAt'] as Timestamp?;
        if (approvedAt != null) {
          history.add(
            HistoryEntry(
              date: approvedAt.toDate(),
              amount: (data['principal'] ?? 0.0).toDouble(),
              operation: 'Loan Approved',
              description:
                  'Loan of ₱${_formatCurrency((data['principal'] ?? 0.0).toDouble())} approved',
              loanId: doc.id,
            ),
          );
        }
      }

      // Add payments
      for (final doc in payments.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final amount = (data['amount'] ?? 0.0).toDouble();
          final paymentMethod = data['paymentMethod'] ?? 'Unknown';
          final notes = data['notes'] ?? '';
          final receiptId = data['receiptId'];

          history.add(
            HistoryEntry(
              date: timestamp.toDate(),
              amount: amount,
              operation: 'Payment',
              description:
                  'Payment of ₱${_formatCurrency(amount)} via ${_getPaymentMethodName(paymentMethod)}${notes.isNotEmpty ? ' - $notes' : ''}',
              loanId: data['loanId'],
              paymentMethod: paymentMethod,
              receiptId: receiptId,
              paymentId: doc.id,
            ),
          );
        }
      }

      // Sort by date (most recent first)
      history.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _allHistory.addAll(history);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReceiptDetails(HistoryEntry entry) async {
    try {
      if (entry.receiptId == null) {
        _showInfoDialog(
          'No Receipt Available',
          'No receipt is available for this transaction.',
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading receipt details...'),
            ],
          ),
        ),
      );

      // Fetch receipt from Firestore
      final receiptDoc = await FirebaseFirestore.instance
          .collection('receipts')
          .doc(entry.receiptId)
          .get();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!receiptDoc.exists) {
        _showInfoDialog(
          'Receipt Not Found',
          'Receipt details could not be found for this transaction.',
        );
        return;
      }

      final receiptData = receiptDoc.data()!;
      _showReceiptDialog(receiptData, entry);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showInfoDialog(
        'Error',
        'Failed to load receipt: $e',
      );
    }
  }

  void _showReceiptDialog(Map<String, dynamic> receiptData, HistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Receipt Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReceiptDetailRow('Receipt Number', receiptData['receiptNumber'] ?? 'N/A'),
              _buildReceiptDetailRow('Transaction Date', _formatDetailedDate(entry.date)),
              _buildReceiptDetailRow('Amount', '₱${_formatCurrencyDetailed(receiptData['amount'] ?? 0.0)}'),
              _buildReceiptDetailRow('Payment Method', _getPaymentMethodName(receiptData['paymentMethod'] ?? 'Unknown')),
              _buildReceiptDetailRow('Previous Balance', '₱${_formatCurrencyDetailed(receiptData['previousBalance'] ?? 0.0)}'),
              _buildReceiptDetailRow('New Balance', '₱${_formatCurrencyDetailed(receiptData['newBalance'] ?? 0.0)}'),
              
              if (receiptData['isFullPayment'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Full Payment - Loan Completed',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (receiptData['notes'] != null && receiptData['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  receiptData['notes'].toString(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Transaction ID: ${entry.paymentId ?? 'N/A'}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'Receipt ID: ${entry.receiptId ?? 'N/A'}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatCurrencyDetailed(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'saved_cards':
        return 'Credit/Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash_branch':
        return 'Cash at Branch';
      case 'wallet':
        return 'Digital Wallet';
      default:
        return 'Unknown';
    }
  }

  List<HistoryEntry> get _filteredHistory {
    if (_selectedFilter == 'all') return _allHistory;
    return _allHistory
        .where(
          (entry) => entry.operation.toLowerCase().contains(
            _selectedFilter.toLowerCase(),
          ),
        )
        .toList();
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildHistoryItem(HistoryEntry entry) {
    Color getOperationColor() {
      switch (entry.operation) {
        case 'Payment':
          return Colors.green;
        case 'Loan Application':
          return Colors.blue;
        case 'Loan Approved':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    IconData getOperationIcon() {
      switch (entry.operation) {
        case 'Payment':
          return Icons.payment;
        case 'Loan Application':
          return Icons.send;
        case 'Loan Approved':
          return Icons.check_circle;
        default:
          return Icons.history;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: getOperationColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getOperationIcon(),
              color: getOperationColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.operation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${_formatCurrency(entry.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: entry.operation == 'Payment'
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              if (entry.paymentMethod != null)
                Text(
                  _getPaymentMethodName(entry.paymentMethod!),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          // Info icon for payments with receipts
          if (entry.operation == 'Payment' && entry.receiptId != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              onPressed: () => _showReceiptDetails(entry),
              tooltip: 'View Receipt Details',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/userDashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading transaction history...'),
                ],
              ),
            )
          : Column(
              children: [
                // Filter and summary
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_filteredHistory.length} records',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Filter buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('payment', 'Payments'),
                            const SizedBox(width: 8),
                            _buildFilterChip('loan', 'Loans'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // History list
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your transaction history will appear here',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '💡 Payments with receipts will show an info icon',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryItem(_filteredHistory[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}