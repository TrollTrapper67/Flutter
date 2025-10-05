import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_project_final/screens/user_credibility.dart';
import 'package:flutter_project_final/screens/edit_user_profile.dart';
import 'package:flutter_project_final/screens/change_password_screen.dart'; // Add this import

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _userData = {
              'email': user.email,
              'name': 'Not set',
              'phone': 'Not provided',
            };
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  // Reload function
  Future<void> _reloadData() async {
    await _loadUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile data refreshed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get credibility score with color coding
  Widget _buildCredibilityScore() {
    final credibility = _userData?['credibilityScore'] ?? 0;
    Color scoreColor;
    String status;
    
    if (credibility >= 80) {
      scoreColor = Colors.green;
      status = 'Excellent';
    } else if (credibility >= 60) {
      scoreColor = Colors.blue;
      status = 'Good';
    } else if (credibility >= 40) {
      scoreColor = Colors.orange;
      status = 'Fair';
    } else {
      scoreColor = Colors.red;
      status = 'Poor';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$credibility',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '/100',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            fontSize: 16,
            color: scoreColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Reload button in AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Profile',
            onPressed: _reloadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(
                  child: Text(
                    'Please log in to view profile',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _reloadData, // Pull-to-refresh functionality
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Profile Header - MADE BIGGER
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0), // Increased padding
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50, // Increased from 40 to 50
                                  backgroundColor: Colors.blue,
                                  backgroundImage: _userData?['profileImageUrl'] != null 
                                      ? NetworkImage(_userData!['profileImageUrl'])
                                      : null,
                                  child: _userData?['profileImageUrl'] == null
                                      ? Text(
                                          _userData?['name']?.toString().substring(0, 1).toUpperCase() ?? 
                                          user.email?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            fontSize: 40, // Increased from 32 to 40
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 20), // Increased spacing
                                Text(
                                  _userData?['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 28, // Increased from 24 to 28
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.email ?? 'No email',
                                  style: TextStyle(
                                    fontSize: 18, // Increased from 16 to 18
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Chip(
                                  label: Text(
                                    _userData?['role']?.toString().toUpperCase() ?? 'USER',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16, // Increased font size
                                    ),
                                  ),
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                const SizedBox(height: 16),
                                // Added user stats row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem('Credibility', '${_userData?['credibilityScore'] ?? 0}'),
                                    _buildStatItem('Loans', '${_userData?['totalLoans'] ?? 0}'),
                                    _buildStatItem('Status', _userData?['accountStatus'] ?? 'Active'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Credibility Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified_user, color: Colors.purple, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'User Credibility',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildCredibilityScore(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your credibility score helps determine your loan eligibility and terms. Keep your profile updated and maintain good payment history to improve your score.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const UserCredibilityScreen(),
                                        ),
                                      ).then((_) {
                                        // Reload data when returning from credibility screen
                                        _reloadData();
                                      });
                                    },
                                    icon: const Icon(Icons.update),
                                    label: const Text('Update Credibility'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Information
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Email', user.email ?? 'Not available'),
                                _buildInfoRow('Name', _userData?['name'] ?? 'Not set'),
                                _buildInfoRow('Phone', _userData?['phone'] ?? 'Not provided'),
                                if (_userData?['createdAt'] != null)
                                  _buildInfoRow('Member Since', _formatDate(_userData!['createdAt'])),
                                if (_userData?['updatedAt'] != null)
                                  _buildInfoRow('Last Updated', _formatDate(_userData!['updatedAt'])),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Navigate to edit profile screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditUserProfile(
                                            onProfileUpdated: _reloadData,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Profile'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Navigate to change password screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChangePasswordScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.lock),
                                    label: const Text('Change Password'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Helper widget for stat items in the big profile card
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}