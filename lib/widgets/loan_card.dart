// lib/widgets/loan_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanCard extends StatelessWidget {
  final String id;
  final String title;
  final double principal;
  final double balance;
  final String status; // 'active', 'pending', 'late', 'closed'
  final DateTime nextPayment;
  final VoidCallback? onTap;

  const LoanCard({
    required this.id,
    required this.title,
    required this.principal,
    required this.balance,
    required this.status,
    required this.nextPayment,
    this.onTap,
    super.key,
  });

  Color _statusColor() {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Remaining ${nf.format(balance)}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor().withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Text('Next: ${DateFormat.yMMMd().format(nextPayment)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(nf.format(principal), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onTap,
                    child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

