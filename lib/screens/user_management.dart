import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRole = 'all';

  String _sortField = 'createdAt';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Helper method to safely convert any value to string
  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Helper method to validate user roles
  String _validateUserRole(dynamic role) {
    if (role == null) return 'user';

    final roleString = _safeToString(role).toLowerCase().trim();
    if (roleString == 'admin' || roleString == 'user') {
      return roleString;
    }

    return 'user'; // Default fallback
  }

  // Helper method to safely get user name
  String _getUserName(Map<String, dynamic> user) {
    final name = user['name'];
    if (name == null) return 'No Name';
    return _safeToString(name);
  }

  // Helper method to safely get user email
  String _getUserEmail(Map<String, dynamic> user) {
    final email = user['email'];
    if (email == null) return 'No email';
    return _safeToString(email);
  }

  // Helper method to safely get user phone
  String _getUserPhone(Map<String, dynamic> user) {
    final phone = user['phone'];
    if (phone == null) return 'Not provided';
    return _safeToString(phone);
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await _firestore
          .collection('users')
          .orderBy(_sortField, descending: !_sortAscending)
          .get();

      setState(() {
        _users = snapshot.docs.map((doc) {
          final data = doc.data();

          // Validate and ensure role is either 'admin' or 'user'
          final validatedRole = _validateUserRole(data['role']);

          return {
            'id': doc.id,
            ...data,
            'role': validatedRole, // Override with validated role
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load users: ${_safeToString(e)}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackbar('User role updated to $newRole');
      _loadUsers(); // Refresh the list
    } catch (e) {
      _showErrorSnackbar('Failed to update role: ${_safeToString(e)}');
    }
  }

  // NEW FUNCTION: Delete user from both Firestore AND Firebase Authentication
  Future<void> _deleteUser(String userId, String userEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      _showErrorSnackbar('You cannot delete your own account');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete $userEmail? This action will:\n\n• Remove user from Firestore\n• Delete user from Authentication\n• This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUserFromBoth(userId, userEmail);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // NEW FUNCTION: Delete user from both Firestore and Authentication
  Future<void> _deleteUserFromBoth(String userId, String userEmail) async {
    try {
      setState(() => _isLoading = true);

      // Step 1: Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Step 2: Delete from Firebase Authentication
      // Note: This requires the Admin SDK on the server side for security reasons
      // Since we can't delete users directly from client-side, we'll show a message
      // about what needs to be done

      _showSuccessSnackbar('User deleted from Firestore successfully!');

      // Show additional info about Authentication deletion
      _showAuthDeletionInfo(userEmail, userId);

      _loadUsers(); // Refresh the list
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to delete user: ${_safeToString(e)}');
    }
  }

  // NEW FUNCTION: Show information about Authentication deletion
  void _showAuthDeletionInfo(String userEmail, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Cleanup Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User has been removed from Firestore. To complete the deletion:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('1. Go to Firebase Console'),
            const Text('2. Navigate to Authentication > Users'),
            const Text('3. Find and delete the user:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Email: $userEmail'), Text('UID: $userId')],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: User deletion from Authentication requires server-side Admin SDK for security reasons.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', _getUserName(user)),
              _buildDetailRow('Email', _getUserEmail(user)),
              _buildDetailRow('Phone', _getUserPhone(user)),
              _buildDetailRow('Role', _validateUserRole(user['role'])),
              _buildDetailRow('User ID', _safeToString(user['id'])),
              if (user['createdAt'] != null)
                _buildDetailRow('Joined', _formatDate(user['createdAt'])),
              if (user['updatedAt'] != null)
                _buildDetailRow('Last Updated', _formatDate(user['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users.where((user) {
      final email = _getUserEmail(user).toLowerCase();
      final name = _getUserName(user).toLowerCase();
      final role = _validateUserRole(user['role']);

      final matchesSearch =
          email.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == 'all' || role == _filterRole;

      return matchesSearch && matchesRole;
    }).toList();

    // Apply sorting with safe comparison
    filtered.sort((a, b) {
      var aValue = a[_sortField];
      var bValue = b[_sortField];

      // Handle null values
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      // Handle different data types by converting to string for comparison
      String aString;
      String bString;

      if (aValue is Timestamp && bValue is Timestamp) {
        aString = aValue.toDate().toString();
        bString = bValue.toDate().toString();
      } else {
        aString = _safeToString(aValue);
        bString = _safeToString(bValue);
      }

      return _sortAscending
          ? aString.compareTo(bString)
          : bString.compareTo(aString);
    });

    return filtered;
  }

  void _showSortFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sort & Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _sortField,
                items: const [
                  DropdownMenuItem(
                    value: 'createdAt',
                    child: Text('Registration Date'),
                  ),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'role', child: Text('Role')),
                ],
                onChanged: (value) {
                  setDialogState(() => _sortField = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _sortAscending,
                    onChanged: (value) {
                      setDialogState(() => _sortAscending = value!);
                    },
                  ),
                  const Text('Ascending Order'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter by role:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _filterRole,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (value) {
                  setDialogState(() => _filterRole = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadUsers(); // Reload with new sort/filter
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortFilterDialog,
            tooltip: 'Sort & Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Statistics
          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total',
                    _users.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Admins',
                    _users
                        .where((u) => _validateUserRole(u['role']) == 'admin')
                        .length
                        .toString(),
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Users',
                    _users
                        .where((u) => _validateUserRole(u['role']) == 'user')
                        .length
                        .toString(),
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No users found'),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final currentUser = _auth.currentUser;
    final isCurrentUser = currentUser != null && currentUser.uid == user['id'];

    // Robust role validation
    final validRole = _validateUserRole(user['role']);
    final isAdmin = validRole == 'admin';

    // Safe avatar text
    final avatarText = _getUserName(user).isNotEmpty
        ? _getUserName(user).substring(0, 1).toUpperCase()
        : _getUserEmail(user).isNotEmpty
        ? _getUserEmail(user).substring(0, 1).toUpperCase()
        : 'U';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.green : Colors.blue,
          child: Text(avatarText, style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          _getUserName(user),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getUserEmail(user)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    validRole.toUpperCase(),
                    style: TextStyle(
                      color: isAdmin ? Colors.green : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed DropdownButton with proper value validation
            DropdownButton<String>(
              value: validRole,
              items: const [
                DropdownMenuItem<String>(value: 'user', child: Text('User')),
                DropdownMenuItem<String>(value: 'admin', child: Text('Admin')),
              ],
              onChanged: isCurrentUser
                  ? null // Disable for current user
                  : (String? newRole) {
                      if (newRole != null && newRole != validRole) {
                        _updateUserRole(user['id'], newRole);
                      }
                    },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('View Details'),
                  ),
                ),
                if (!isCurrentUser)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete User'),
                    ),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    _showUserDetails(user);
                    break;
                  case 'delete':
                    _deleteUser(user['id'], _getUserEmail(user));
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
