// lib/screens/history.dart
import 'package:flutter/material.dart';

class HistoryEntry {
  final DateTime date;
  final int amount; // stored as integer pesos
  final String operation; // e.g. "Payment", "Loan", "Adjustment"

  HistoryEntry({required this.date, required this.amount, required this.operation});
}

class HistoryPage extends StatefulWidget {
  static const routeName = '/history';
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<HistoryEntry> _items = [
    HistoryEntry(date: DateTime.now().subtract(const Duration(days: 1)), amount: 55000, operation: 'Loan issued'),
    HistoryEntry(date: DateTime.now().subtract(const Duration(days: 1)), amount: 5000, operation: 'Partial payment'),
    HistoryEntry(date: DateTime.now().subtract(const Duration(days: 3)), amount: 10000, operation: 'Payment'),
  ];

  String _formatAmount(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(',');
    }
    return buf.toString().split('').reversed.join();
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildCard(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('${_items.length} records', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export not implemented')));
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildCard(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 48,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Operation')),
                    ],
                    rows: _items.map((e) {
                      return DataRow(cells: [
                        DataCell(Text('${e.date.year}-${e.date.month.toString().padLeft(2,'0')}-${e.date.day.toString().padLeft(2,'0')}')),
                        DataCell(Text('₱ ${_formatAmount(e.amount)}')),
                        DataCell(Text(e.operation)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
