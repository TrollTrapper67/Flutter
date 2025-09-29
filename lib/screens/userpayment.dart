// lib/screens/payment.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  static const routeName = '/payment';
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _confirmPayment() async {
    if (_amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount to pay')),
      );
      return;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text('Proceed to pay ₱ ${_formatWithCommas(_amountValue.toString())}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes, proceed')),
        ],
      ),
    );

    if (yes != true) return;

    // --- SAFETY CHECK: widget might have been removed while awaiting user input ---
    if (!mounted) return;

    // Show success dialog. Use the dialog's ctx for navigation to avoid issues.
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Balance paid successfully'),
          content: const Text('Your payment has been recorded.'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          actions: [
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.of(ctx).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _amountController.text.isEmpty ? '-' : '₱ ${_amountController.text}';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), centerTitle: true, elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How much did you pay?', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '0',
                      prefixIcon: Icon(Icons.payments),
                    ),
                    onChanged: _onAmountChanged,
                  ),
                  const SizedBox(height: 8),
                  Text('Entered: $formattedAmount', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. partial payment'),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _amountValue > 0 ? _confirmPayment : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Pay', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
