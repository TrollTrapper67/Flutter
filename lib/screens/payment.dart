import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_1/screens/history.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateAmount(String? text) {
    if (text == null || text.trim().isEmpty) return 'Enter an amount';
    final cleaned = text.replaceAll(',', '');
    final value = double.tryParse(cleaned);
    if (value == null) return 'Invalid number';
    if (value <= 0) return 'Amount must be greater than zero';
    return null;
  }

  double _parseAmount(String text) {
    return double.parse(text.replaceAll(',', ''));
  }

  Future<void> _onProceed() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _isProcessing = true);
    final amount = _parseAmount(_controller.text);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text('Proceed with payment of ₱${amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes, proceed')),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final item = HistoryItem(date: DateTime.now(), amount: amount, operation: 'Payment');

      // Small simulated processing delay
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      // Navigate to history with the single item (for testing without a DB)
      Navigator.pushNamed(context, '/history', arguments: [item]);
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  List<TextInputFormatter> _inputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;

        // disallow multiple dots
        if ('..'.allMatches(text).isNotEmpty) return oldValue;

        // disallow leading zero followed by digit (except "0." case)
        if (text.length > 1 && text[0] == '0' && text[1] != '.') {
          final cleaned = text.replaceFirst(RegExp(r'^0+'), '');
          return TextEditingValue(
            text: cleaned.isEmpty ? '0' : cleaned,
            selection: TextSelection.collapsed(offset: cleaned.length),
          );
        }

        // limit to 2 decimal places if a dot exists
        if (text.contains('.')) {
          final parts = text.split('.');
          if (parts.length > 1 && parts[1].length > 2) {
            return oldValue;
          }
        }

        return newValue;
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 16),
                  child: Column(
                    children: [
                      const Text(
                        'How much did you pay?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: _inputFormatters(),
                                validator: _validateAmount,
                                decoration: InputDecoration(
                                  prefixText: '₱ ',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isProcessing)
                        const LinearProgressIndicator()
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _onProceed,
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isProcessing
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Proceed', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Tip: enter numbers only. You can include cents (e.g. 1500.50).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
