// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _usersWithLoans = [];
  bool _isLoading = true;
  String _selectedUserId = '';
  String _messageType = 'payment_reminder';
  final TextEditingController _customMessageController = TextEditingController();

  // Predefined message templates
  final Map<String, String> _messageTemplates = {
    'payment_reminder': '🔔 Friendly reminder: Your loan payment is due soon. Please make your payment to avoid any late fees.',
    'overdue_payment': '⚠️ URGENT: Your loan payment is overdue. Please make the payment immediately to avoid penalties.',
    'general_reminder': '📋 Reminder: Please check your loan account for important updates regarding your payment schedule.',
    'custom': '', // Custom message will be entered by admin
  };

  @override
  void initState() {
    super.initState();
    _loadUsersWithActiveLoans();
  }

  Future<void> _loadUsersWithActiveLoans() async {
    try {
      // Get all active loans
      final activeLoans = await _firestore
          .collection('user_loans')
          .where('status', isEqualTo: 'active')
          .get();

      final usersWithLoans = <Map<String, dynamic>>[];

      for (var loanDoc in activeLoans.docs) {
        final loanData = loanDoc.data() as Map<String, dynamic>;
        final userId = loanData['userId'] as String?;

        if (userId != null && userId.isNotEmpty) {
          // Get user details
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>? ?? {};
            usersWithLoans.add({
              'userId': userId,
              'userName': userData['name'] ?? 'Unknown User',
              'userEmail': userData['email'] ?? 'Unknown Email',
              'loanData': loanData,
              'loanId': loanDoc.id,
            });
          }
        }
      }

      setState(() {
        _usersWithLoans = usersWithLoans;
        _isLoading = false;
        if (_usersWithLoans.isNotEmpty) {
          _selectedUserId = _usersWithLoans.first['userId'] as String;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedUserId.isEmpty) {
      _showError('Please select a user');
      return;
    }

    final selectedUser = _usersWithLoans.firstWhere(
      (user) => user['userId'] == _selectedUserId,
    );

    final message = _messageType == 'custom' 
        ? _customMessageController.text.trim()
        : _messageTemplates[_messageType]!;

    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    try {
      // Send notification to user
      await _sendNotification(
        userId: _selectedUserId,
        title: _getMessageTitle(_messageType),
        message: message,
        type: _getMessageType(_messageType),
        action: 'view_loan',
      );

      // Log the message in admin logs
      await _firestore.collection('admin_logs').add({
        'action': 'sent_message',
        'userName': selectedUser['userName'],
        'userEmail': selectedUser['userEmail'],
        'messageType': _messageType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Message sent to ${selectedUser['userName']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear custom message if used
      if (_messageType == 'custom') {
        _customMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error sending message: $e');
      }
    }
  }

  Future<void> _sendBulkMessage() async {
    if (_usersWithLoans.isEmpty) {
      _showError('No users with active loans found');
      return;
    }

    final message = _messageType == 'custom' 
        ? _customMessageController.text.trim()
        : _messageTemplates[_messageType]!;

    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Bulk Message'),
        content: Text(
          'This will send the message to all ${_usersWithLoans.length} users with active loans. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Send to All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      int successCount = 0;
      
      for (var user in _usersWithLoans) {
        try {
          await _sendNotification(
            userId: user['userId'] as String,
            title: _getMessageTitle(_messageType),
            message: message,
            type: _getMessageType(_messageType),
            action: 'view_loan',
          );
          successCount++;
        } catch (e) {
          print('Error sending to ${user['userName']}: $e');
        }
      }

      // Log bulk message
      await _firestore.collection('admin_logs').add({
        'action': 'sent_bulk_message',
        'recipientCount': successCount,
        'totalCount': _usersWithLoans.length,
        'messageType': _messageType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Message sent to $successCount/${_usersWithLoans.length} users'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear custom message if used
      if (_messageType == 'custom') {
        _customMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error sending bulk messages: $e');
      }
    }
  }

  // Local notification sending function
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String action,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'action': action,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  String _getMessageTitle(String type) {
    switch (type) {
      case 'payment_reminder':
        return 'Payment Reminder 💰';
      case 'overdue_payment':
        return 'Overdue Payment Alert ⚠️';
      case 'general_reminder':
        return 'Important Reminder 📋';
      case 'custom':
        return 'Message from Admin 📨';
      default:
        return 'Admin Message';
    }
  }

  String _getMessageType(String type) {
    switch (type) {
      case 'overdue_payment':
        return 'warning';
      case 'loan_approved':
        return 'success';
      default:
        return 'info';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Reminders'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usersWithLoans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No users with active loans',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All users have either paid off their loans or have no active loans.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Selection
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedUserId.isNotEmpty ? _selectedUserId : null,
                                decoration: const InputDecoration(
                                  labelText: 'Choose User',
                                  border: OutlineInputBorder(),
                                ),
                                items: _usersWithLoans.map((user) {
                                  final loanData = user['loanData'] as Map<String, dynamic>;
                                  final remainingBalance = (loanData['remainingBalance'] ?? 0.0) as double;
                                  return DropdownMenuItem<String>(
                                    value: user['userId'] as String,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${user['userName']} - Balance: ₱${remainingBalance.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUserId = value ?? '';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message Type Selection
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Message Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._messageTemplates.keys.map((type) {
                                return RadioListTile<String>(
                                  value: type,
                                  groupValue: _messageType,
                                  onChanged: (value) {
                                    setState(() {
                                      _messageType = value ?? 'payment_reminder';
                                    });
                                  },
                                  title: Text(_getMessageTitle(type).replaceAll(RegExp(r'[^\w\s]'), '')),
                                  subtitle: type != 'custom' 
                                      ? Text(_messageTemplates[type]!)
                                      : null,
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom Message Input (only for custom type)
                      if (_messageType == 'custom')
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Custom Message',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customMessageController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your custom message here...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendMessage,
                              icon: const Icon(Icons.send),
                              label: const Text('Send to Selected User'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sendBulkMessage,
                              icon: const Icon(Icons.person_2),
                              label: Text('Send to All Users (${_usersWithLoans.length})'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Theme.of(context).primaryColor),
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