import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../affordability/affordability_modal.dart';

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
  bool _showAffordabilityModal = false;

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

  // Show affordability modal before applying loan
  void _showAffordabilityModalFunc() {
    setState(() {
      _showAffordabilityModal = true;
    });
  }

  // Handle modal close
  void _closeAffordabilityModal() {
    setState(() {
      _showAffordabilityModal = false;
    });
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

    try {
      await FirebaseFirestore.instance.collection("loan_applications").add({
        "userId": user.uid,
        "email": user.email,
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
        _showAffordabilityModal =
            false; // Close modal after successful application
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
      body: Stack(
        children: [
          // Main loan form content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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

                // 🔹 Apply Loan Button (now shows affordability modal first)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_principal > 0 && _months > 0)
                        ? _showAffordabilityModalFunc
                        : null,
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

          // Affordability modal overlay (shows only when modal is active)
          if (_showAffordabilityModal)
            AffordabilityModal(
              isOpen: _showAffordabilityModal,
              onClose: _closeAffordabilityModal,
              onApplyLoan: _applyLoan,
              onSkipToFullApplication: _applyLoan,
              currentLoanAmount: _principal,
              currentLoanTerm: _months,
            ),
        ],
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