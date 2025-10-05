// lib/screens/apply_stepper.dart
import 'package:flutter/material.dart';
import '../widgets/loading.dart';
import '../services/loan_service.dart'; // keep your existing service; do not modify it

class ApplyStepper extends StatefulWidget {
  final String userId;
  const ApplyStepper({required this.userId, super.key});

  @override
  State<ApplyStepper> createState() => _ApplyStepperState();
}

class _ApplyStepperState extends State<ApplyStepper> {
  int step = 0;
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  final Map<String, dynamic> form = {};

  void nextStep() async {
    final valid = _formKeys[step].currentState?.validate() ?? false;
    if (!valid) return;
    _formKeys[step].currentState?.save();
    if (step == 2) {
      await showLoading(context, text: 'Submitting application...');
      try {
        await LoanService.submitApplication(widget.userId, form);
        if (!mounted) return;
        Navigator.of(context).pop(); // close apply flow on success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      } finally {
        if (mounted) {
          hideLoading(context);
        }
      }
      return;
    }
    setState(() => step++);
  }

  void back() {
    if (step > 0) setState(() => step--);
  }

  @override
  Widget build(BuildContext context) {
    final steps = [_buildDetails(), _buildReview(), _buildDocs()];
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(3, (i) {
                final active = i == step;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, child: Text('${i+1}', style: const TextStyle(color: Colors.white))),
                      const SizedBox(height: 6),
                      Text(['Details','Review','Docs'][i], style: TextStyle(fontSize: 12, color: active ? Colors.black : Colors.black54)),
                    ],
                  ),
                );
              }),
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: steps[step])),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (step > 0) OutlinedButton(onPressed: back, child: const Text('Back')),
                  const Spacer(),
                  ElevatedButton(onPressed: nextStep, child: Text(step == 2 ? 'Submit' : 'Next')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Form(
      key: _formKeys[0],
      child: ListView(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
            onSaved: (v) => form['amount'] = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Term (months)'),
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.isEmpty) ? 'Enter term' : null,
            onSaved: (v) => form['term'] = v,
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    // keep this simple, UI only. Back-end calc used in real app.
    final amt = form['amount'] ?? '—';
    final term = form['term'] ?? '—';
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review your loan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Amount: $amt'),
          const SizedBox(height: 6),
          Text('Term: $term months'),
          const SizedBox(height: 12),
          const Text('Estimated monthly: ₱X, total repayable: ₱Y'),
        ],
      ),
    );
  }

  Widget _buildDocs() {
    return Form(
      key: _formKeys[2],
      child: Column(
        children: [
          const Text('Upload ID and documents'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Upload')),
        ],
      ),
    );
  }
}

