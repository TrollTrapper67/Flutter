import 'package:flutter/material.dart';

class HistoryItem {
  final DateTime date;
  final double amount;
  final String operation; // e.g. "Loan", "Payment", etc.

  HistoryItem({
    required this.date,
    required this.amount,
    required this.operation,
  });
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.items = const []});

  final List<HistoryItem> items;

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatAmount(double a) {
    return '₱${a.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final list = items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No history yet.'),
                  SizedBox(height: 6),
                  Text('No transactions available — database/auth not connected.'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final it = list[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(it.operation.isNotEmpty ? it.operation[0].toUpperCase() : '?'),
                  ),
                  title: Text(it.operation),
                  subtitle: Text(_formatDate(it.date)),
                  trailing: Text(
                    _formatAmount(it.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }
}
