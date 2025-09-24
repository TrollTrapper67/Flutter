import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_1/screens/history.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  // User-adjustable fields
  double _annualRate = 0.05;
  int _termMonths = 12;

  // store listener so we can remove it cleanly
  late final VoidCallback _amountListener;

  @override
  void initState() {
    super.initState();
    _amountListener = () {
      // update estimate live while user types
      if (mounted) setState(() {});
    };
    _amountController.addListener(_amountListener);
  }

  @override
  void dispose() {
    _amountController.removeListener(_amountListener);
    _amountController.dispose();
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

  // Amortizing monthly payment formula
  double _monthlyPayment(double principal, double annualRate, int months) {
    if (months <= 0 || principal <= 0) return 0.0;
    final monthlyRate = annualRate / 12.0;
    if (monthlyRate == 0) return principal / months;
    final denom = 1 - math.pow(1 + monthlyRate, -months);
    return principal * monthlyRate / denom;
  }

  // Friendly input rules: digits and one dot, up to 2 decimals
  List<TextInputFormatter> _inputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;
        // prevent multiple dots
        if ('..'.allMatches(text).isNotEmpty) return oldValue;
        // prevent weird leading zeros like "00" (allow "0.")
        if (text.length > 1 && text[0] == '0' && text[1] != '.') {
          final cleaned = text.replaceFirst(RegExp(r'^0+'), '');
          return TextEditingValue(
            text: cleaned.isEmpty ? '0' : cleaned,
            selection: TextSelection.collapsed(offset: (cleaned.isEmpty ? 1 : cleaned.length)),
          );
        }
        // max 2 decimals
        if (text.contains('.')) {
          final parts = text.split('.');
          if (parts.length > 1 && parts[1].length > 2) return oldValue;
        }
        return newValue;
      }),
    ];
  }

  Future<void> _onProceed() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _isProcessing = true);
    final amount = _parseAmount(_amountController.text);
    final estMonthly = _monthlyPayment(amount, _annualRate, _termMonths);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loan amount: ₱${amount.toStringAsFixed(2)}'),
            Text('Term: $_termMonths months'),
            Text('APR: ${(_annualRate * 100).toStringAsFixed(2)}%'),
            const SizedBox(height: 8),
            Text('Estimated monthly: ₱${estMonthly.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );

    // must check mounted before using context after an await
    if (!mounted) return;

    if (confirmed == true) {
      final item = HistoryItem(date: DateTime.now(), amount: amount, operation: 'Loan');

      // short UX delay to show progress briefly
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Navigate to history for now (passing the single item).
      Navigator.pushNamed(context, '/history', arguments: [item]);
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final amount = (_amountController.text.isEmpty)
        ? 0.0
        : double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final estMonthly = _monthlyPayment(amount, _annualRate, _termMonths);

    return Scaffold(
      appBar: AppBar(title: const Text('Loan')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    children: [
                      const Text(
                        'How much did you loan?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: _inputFormatters(),
                          validator: _validateAmount,
                          decoration: InputDecoration(
                            prefixText: '₱ ',
                            hintText: '0.00',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              // use value for older SDK compatibility (zapp.run)
                              value: _termMonths,
                              items: [6, 12, 24, 36, 48]
                                  .map((m) => DropdownMenuItem(value: m, child: Text('$m months')))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _termMonths = v);
                              },
                              decoration: const InputDecoration(labelText: 'Term'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('APR', style: TextStyle(fontSize: 12)),
                                Slider(
                                  value: _annualRate,
                                  min: 0.0,
                                  max: 0.2,
                                  divisions: 20,
                                  label: '${(_annualRate * 100).toStringAsFixed(1)}%',
                                  onChanged: (v) => setState(() => _annualRate = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Estimated monthly:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('₱${estMonthly.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isProcessing) const LinearProgressIndicator() else const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 12),
              const Text(
                'Tip: use the slider to tweak APR for different scenarios.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
