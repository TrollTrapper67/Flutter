// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoanPage extends StatefulWidget {
  static const routeName = '/loan';
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _customMonthsController = TextEditingController();
  int? _selectedMonths;
  final List<int> _presetMonths = [6, 12, 24, 36, 48, 60];
  bool _useCustom = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch user name from Firestore
  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userName = userData?['name'] ?? 'Unknown User';
          });
        } else {
          setState(() {
            _userName = 'Unknown User';
          });
        }
      } catch (e) {
        setState(() {
          _userName = 'Unknown User';
        });
      }
    }
  }

  double get _principal {
    final t = _principalController.text.replaceAll(',', '');
    if (t.isEmpty) return 0;
    return double.tryParse(t) ?? 0;
  }

  int get _months {
    if (_useCustom) {
      final t = _customMonthsController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final v = int.tryParse(t);
      if (v != null && v > 0) return v;
      return 0;
    }
    return _selectedMonths ?? 0;
  }

  String _formatAmount(double v) {
    if (v.isNaN || v.isInfinite) return '-';
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formatted = intPart.replaceAllMapped(regex, (m) => ',');
    return '$formatted.$decPart';
  }

  String _formatCurrencyInput(String value) {
    // Remove all non-digits and decimal points
    String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');

    // If empty, return empty
    if (cleaned.isEmpty) return '';

    // Split by decimal point
    List<String> parts = cleaned.split('.');

    // Add commas to the integer part
    if (parts.isNotEmpty) {
      String integerPart = parts[0];
      String formatted = integerPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

      // Rejoin with decimal part if it exists
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return '$formatted.${parts[1]}';
      }
      return formatted;
    }

    return cleaned;
  }

  double get _monthlyPayment {
    final m = _months;
    if (m <= 0) return 0;
    return _principal / m; // simple division
  }

  // Check user credibility score before applying loan
  Future<bool> _checkCredibilityScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final credibilityScore = userDoc.data()?['credibilityScore'] ?? 0;
        // Assuming score ranges from 0-100, with <50 being low
        return credibilityScore >= 50;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Show low credibility score popup
  void _showLowCredibilityPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Low Credibility Score'),
            ],
          ),
          content: const Text(
            'Your credibility score is currently too low to apply for a loan. '
            'Please improve your financial standing and try again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyLoan() async {
    if (_principal <= 0 || _months <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid loan amount and term")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    // Check credibility score first
    final hasGoodCredibility = await _checkCredibilityScore();
    if (!hasGoodCredibility) {
      _showLowCredibilityPopup();
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("loan_applications").add({
        "userId": user.uid,
        "email": user.email,
        "name": _userName ?? 'Unknown User', // Store user name
        "principal": _principal,
        "months": _months,
        "monthlyPayment": _monthlyPayment,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Loan application submitted")),
        );
      }

      // Clear input after success
      _principalController.clear();
      _customMonthsController.clear();
      setState(() {
        _selectedMonths = null;
        _useCustom = false;
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        if (e.code == "permission-denied") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Permission denied. Check Firestore rules."),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
      }
    }
  }

  @override
  void dispose() {
    _principalController.dispose();
    _customMonthsController.dispose();
    super.dispose();
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int alpha15 = 38;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/userDashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Card (Optional - to show who is applying)
            if (_userName != null)
              _buildCard(
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Applying as:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _userName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan amount',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _principalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter principal (e.g. 55000)',
                      border: OutlineInputBorder(),
                      prefixText: '₱ ',
                      prefixStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (s) {
                      final formatted = _formatCurrencyInput(s);
                      if (formatted != _principalController.text) {
                        _principalController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose term (months)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetMonths.map((m) {
                      final selected =
                          (_useCustom == false && _selectedMonths == m);
                      return ChoiceChip(
                        label: Text('$m'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _onPresetSelected(m)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(alpha15),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _useCustom,
                        onChanged: (v) => _onUseCustom(v ?? false),
                      ),
                      const SizedBox(width: 8),
                      const Text('Enter custom months'),
                      const Spacer(),
                    ],
                  ),
                  if (_useCustom) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customMonthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Number of months (e.g. 18)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly payment',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _months <= 0
                          ? 'Enter loan amount and term to see monthly payment'
                          : '₱ ${_formatAmount(_monthlyPayment)}',
                      style: TextStyle(
                        fontSize: _months > 0 ? 24 : 14,
                        fontWeight: _months > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _months > 0
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: No interest applied. Monthly payment is principal divided by months.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Apply Loan Button (now checks credibility score first)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_principal > 0 && _months > 0) ? _applyLoan : null,
                icon: const Icon(Icons.send),
                label: const Text('Apply Loan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPresetSelected(int months) {
    setState(() {
      _useCustom = false;
      _selectedMonths = months;
      _customMonthsController.clear();
    });
  }

  void _onUseCustom(bool useCustom) {
    setState(() {
      _useCustom = useCustom;
      if (useCustom) {
        _selectedMonths = null;
      } else {
        _customMonthsController.clear();
      }
    });
  }
}