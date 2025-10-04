// lib/screens/userpayment.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  static const routeName = '/payment';
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Payment method selection
  String _selectedPaymentMethod = 'saved_cards';

  // Real loan balance (fetched from Firestore)
  double _currentBalance = 0.0; // Will be fetched from database
  double _minimumPayment = 0.0; // Will be calculated from loan data
  bool _isLoadingLoanData = true; // Track loading state

  // Payment method limits
  final Map<String, int> _paymentLimits = {
    'saved_cards': 50000,
    'bank_transfer': 100000,
    'cash_branch': 25000,
    'wallet': 10000,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserLoanData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh loan data when page becomes visible
    _fetchUserLoanData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLoanData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Fetching loan data for user: ${user.uid}');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_loans')
          .where('userId', isEqualTo: user.uid)
          .get();

      print('Found ${querySnapshot.docs.length} loans');

      // Filter for active loans in the application
      final activeLoans = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'active';
      }).toList();

      if (activeLoans.isNotEmpty) {
        // Get the most recently approved active loan
        activeLoans.sort((a, b) {
          final aTime = a.data()['approvedAt'] as Timestamp?;
          final bTime = b.data()['approvedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final loanData = activeLoans.first.data();
        final remainingBalance = (loanData['remainingBalance'] ?? 0.0)
            .toDouble();
        final monthlyPayment = (loanData['monthlyPayment'] ?? 0.0).toDouble();

        print('Loan data: balance=$remainingBalance, monthly=$monthlyPayment');

        setState(() {
          _currentBalance = remainingBalance;
          _minimumPayment = monthlyPayment;
          _isLoadingLoanData = false;
        });
      } else {
        print('No active loans found');
        setState(() {
          _currentBalance = 0.0;
          _minimumPayment = 0.0;
          _isLoadingLoanData = false;
        });
      }
    } catch (e) {
      print('Error fetching user loan data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatWithCommas(String digits) {
    if (digits.isEmpty) return '';
    final chars = digits.split('').reversed.toList();
    final pieces = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      final piece = chars.skip(i).take(3).toList().reversed.join();
      pieces.add(piece);
    }
    return pieces.reversed.join(',');
  }

  void _onAmountChanged(String s) {
    final digits = _digitsOnly(s);
    final formatted = _formatWithCommas(digits);
    if (formatted != s) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  int get _amountValue {
    final digits = _digitsOnly(_amountController.text);
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  double get _newBalance => _currentBalance - _amountValue;

  Color get _balanceColor {
    if (_amountValue == 0) return Colors.red;
    if (_newBalance <= 0) return Colors.green;
    if (_amountValue > _currentBalance) return Colors.orange;
    return Colors.blue;
  }

  String get _balanceText {
    if (_amountValue == 0)
      return 'Remaining balance: ₱${_formatWithCommas(_currentBalance.toString())}';
    if (_newBalance <= 0)
      return 'Overpayment: ₱${_formatWithCommas((-1 * _newBalance).toString())}';
    if (_amountValue > _currentBalance) return 'Amount exceeds balance!';
    return 'Remaining balance: ₱${_formatWithCommas(_newBalance.toString())}';
  }

  void _setAmount(double amount) {
    _amountController.text = _formatWithCommas(amount.toInt().toString());
    setState(() {});
  }

  void _showPaymentConfirmation() {
    if (_amountValue <= 0) {
      _showError(
        'Enter an amount between ₱1 and ₱${_formatWithCommas(_currentBalance.toString())}',
      );
      return;
    }

    if (_amountValue > _paymentLimits[_selectedPaymentMethod]!) {
      _showError(
        'Amount exceeds payment method limit of ₱${_formatWithCommas(_paymentLimits[_selectedPaymentMethod]!.toString())}',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to pay ₱${_formatWithCommas(_amountValue.toString())}.',
            ),
            const SizedBox(height: 8),
            Text(
              'New balance will be ₱${_formatWithCommas(_newBalance.toString())}.',
            ),
            const SizedBox(height: 8),
            Text(
              'Payment method: ${_getPaymentMethodName(_selectedPaymentMethod)}',
            ),
            const SizedBox(height: 8),
            const Text('Continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processPayment();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the user's active loan
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_loans')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Filter for active loans in the application
      final activeLoans = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'active';
      }).toList();

      if (activeLoans.isEmpty) {
        _showError('No active loan found');
        return;
      }

      // Get the most recently approved active loan
      activeLoans.sort((a, b) {
        final aTime = a.data()['approvedAt'] as Timestamp?;
        final bTime = b.data()['approvedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final loanDoc = activeLoans.first;
      final newBalance = _newBalance;

      // Update the loan balance in database
      await loanDoc.reference.update({
        'remainingBalance': newBalance,
        'lastPaymentAt': FieldValue.serverTimestamp(),
        'lastPaymentAmount': _amountValue.toDouble(),
      });

      // Create payment record
      await FirebaseFirestore.instance.collection('user_payments').add({
        'userId': user.uid,
        'loanId': loanDoc.id,
        'amount': _amountValue.toDouble(),
        'paymentMethod': _selectedPaymentMethod,
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _currentBalance = newBalance;
        _amountController.clear();
        _notesController.clear();
      });

      _showSuccessToast();
    } catch (e) {
      _showError('Payment failed: $e');
    }
  }

  void _showSuccessToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment successful — ₱${_formatWithCommas(_amountValue.toString())} received. New balance: ₱${_formatWithCommas(_currentBalance.toString())}.',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'saved_cards':
        return 'Saved Cards';
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

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildQuickButton(String label, int amount, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _amountController.text.isEmpty
        ? '-'
        : '₱${_amountController.text}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
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
            tooltip: 'Refresh Loan Data',
            onPressed: _fetchUserLoanData,
          ),
        ],
      ),
      body: _isLoadingLoanData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your loan information...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Current Balance Display
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Current Loan Balance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${_formatWithCommas(_currentBalance.toString())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Payment Buttons
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildQuickButton(
                              'Pay full\n(₱${_formatWithCommas(_currentBalance.toInt().toString())})',
                              _currentBalance.toInt(),
                              () => _setAmount(_currentBalance),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickButton(
                              'Pay min\n(₱${_formatWithCommas(_minimumPayment.toInt().toString())})',
                              _minimumPayment.toInt(),
                              () => _setAmount(_minimumPayment),
                            ),
                            const SizedBox(width: 8),
                            _buildQuickButton('Custom', 0, () {
                              _amountController.clear();
                              setState(() {});
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Payment Amount Input
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter amount (e.g., 6000)',
                            prefixIcon: Icon(Icons.payments),
                            prefixText: '₱',
                          ),
                          onChanged: _onAmountChanged,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Real-time balance display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _balanceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _balanceColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _amountValue > _currentBalance
                                    ? Icons.warning
                                    : Icons.account_balance_wallet,
                                color: _balanceColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _balanceText,
                                  style: TextStyle(
                                    color: _balanceColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Entered: $formattedAmount',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Method Selection
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._paymentLimits.entries.map((entry) {
                          final method = entry.key;
                          final limit = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              value: method,
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                              title: Text(_getPaymentMethodName(method)),
                              subtitle: Text(
                                'Limit: ₱${_formatWithCommas(limit.toString())}',
                              ),
                              activeColor: Theme.of(context).primaryColor,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  // Notes Section
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Add a note about this payment',
                          ),
                          minLines: 1,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

      // Sticky Pay Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _amountValue > 0 ? _showPaymentConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}