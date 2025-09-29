// lib/screens/loan.dart
import 'package:flutter/material.dart';

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

  double get _principal {
    final t = _principalController.text.replaceAll(RegExp(r'[^0-9.]'), '');
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

  double get _monthlyPayment {
    final m = _months;
    if (m <= 0) return 0;
    // Simple division (no APR/interest)
    return _principal / m;
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
    // 0.15 * 255 = 38.25 so we use 38 for alpha
    final int alpha15 = 38;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loan amount', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _principalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Enter principal (e.g. 55000)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    onChanged: (s) {
                      final clean = s.replaceAll(RegExp(r'[^0-9.]'), '');
                      if (clean == s) {
                        setState(() {});
                        return;
                      }
                      _principalController.value = TextEditingValue(
                          text: clean,
                          selection: TextSelection.collapsed(offset: clean.length));
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose term (months)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetMonths.map((m) {
                      final selected = (_useCustom == false && _selectedMonths == m);
                      return ChoiceChip(
                        label: Text('$m'),
                        selected: selected,
                        onSelected: (_) => _onPresetSelected(m),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        selectedColor:
                            Theme.of(context).colorScheme.primary.withAlpha(alpha15),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(value: _useCustom, onChanged: (v) => _onUseCustom(v ?? false)),
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
                  const Text('Monthly payment', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _months <= 0 ? '-' : '₱ ${_formatAmount(_monthlyPayment)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: (_principal > 0 && _months > 0)
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Loan calculation updated')),
                                );
                              }
                            : null,
                        child: const Text('Calculate'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: APR/Tip has been removed (not implemented). The monthly payment is principal divided by months.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
