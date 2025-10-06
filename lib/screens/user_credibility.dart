import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCredibilityScreen extends StatefulWidget {
  const UserCredibilityScreen({super.key});

  @override
  State<UserCredibilityScreen> createState() => _UserCredibilityScreenState();
}

class _UserCredibilityScreenState extends State<UserCredibilityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentScore = 0;

  // Credibility factors
  bool _hasValidID = false;
  bool _hasEmployment = false;
  bool _hasBankAccount = false;
  bool _hasGoodCreditHistory = false;
  bool _hasCollateral = false;
  int _incomeRange = 0; // 0: <20k, 1: 20k-50k, 2: 50k-100k, 3: >100k

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _userData = Map<String, dynamic>.from(data);
            _currentScore = data['credibilityScore'] ?? 0;
            
            // Load existing credibility factors with proper casting
            final factors = data['credibilityFactors'] ?? {};
            final factorsMap = factors is Map<String, dynamic> 
                ? factors 
                : Map<String, dynamic>.from(factors);
            
            _hasValidID = factorsMap['hasValidID'] ?? false;
            _hasEmployment = factorsMap['hasEmployment'] ?? false;
            _hasBankAccount = factorsMap['hasBankAccount'] ?? false;
            _hasGoodCreditHistory = factorsMap['hasGoodCreditHistory'] ?? false;
            _hasCollateral = factorsMap['hasCollateral'] ?? false;
            _incomeRange = factorsMap['incomeRange'] ?? 0;
            
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  int _calculateScore() {
    int score = 0;
    
    // Basic verification (40 points)
    if (_hasValidID) score += 20;
    if (_hasBankAccount) score += 20;
    
    // Financial stability (40 points)
    if (_hasEmployment) score += 20;
    score += _incomeRange * 5; // 0-15 points based on income range
    
    // Credit history (20 points)
    if (_hasGoodCreditHistory) score += 20;
    
    // Additional factors (20 points)
    if (_hasCollateral) score += 20;
    
    return score.clamp(0, 100);
  }

  Future<void> _updateCredibility() async {
    try {
      setState(() => _isSaving = true);
      
      final user = _auth.currentUser;
      if (user != null) {
        final newScore = _calculateScore();
        final credibilityData = {
          'hasValidID': _hasValidID,
          'hasEmployment': _hasEmployment,
          'hasBankAccount': _hasBankAccount,
          'hasGoodCreditHistory': _hasGoodCreditHistory,
          'hasCollateral': _hasCollateral,
          'incomeRange': _incomeRange,
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        // Save ALL details to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'credibilityScore': newScore,
          'credibilityFactors': credibilityData,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _currentScore = newScore;
          _isSaving = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Credibility score updated to $_currentScore! All details saved.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving credibility: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Check if there are unsaved changes
  bool get _hasUnsavedChanges {
    final originalFactors = _userData?['credibilityFactors'] ?? {};
    final originalFactorsMap = originalFactors is Map<String, dynamic>
        ? originalFactors
        : Map<String, dynamic>.from(originalFactors);
    
    final currentFactors = {
      'hasValidID': _hasValidID,
      'hasEmployment': _hasEmployment,
      'hasBankAccount': _hasBankAccount,
      'hasGoodCreditHistory': _hasGoodCreditHistory,
      'hasCollateral': _hasCollateral,
      'incomeRange': _incomeRange,
    };
    
    return !_mapsEqual(originalFactorsMap, currentFactors);
  }

  // Helper method to compare maps
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    
    return true;
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Are you sure you want to leave without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      
      return shouldLeave ?? false;
    }
    
    return true;
  }

  Widget _buildScoreIndicator() {
    Color scoreColor;
    String status;
    
    if (_currentScore >= 80) {
      scoreColor = Colors.green;
      status = 'Excellent';
    } else if (_currentScore >= 60) {
      scoreColor = Colors.blue;
      status = 'Good';
    } else if (_currentScore >= 40) {
      scoreColor = Colors.orange;
      status = 'Fair';
    } else {
      scoreColor = Colors.red;
      status = 'Poor';
    }

    return Card(
      elevation: 4,
      color: scoreColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Current Credibility Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_currentScore',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            Text(
              '/100',
              style: TextStyle(
                fontSize: 18,
                color: scoreColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredibilityFactor(String title, String description, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Update Credibility'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildScoreIndicator(),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Improve your credibility score by updating your information below:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Credibility Factors
                    _buildCredibilityFactor(
                      'Valid Government ID',
                      'Upload a valid government-issued ID for verification',
                      _hasValidID,
                      (value) => setState(() => _hasValidID = value),
                    ),
                    const SizedBox(height: 12),

                    _buildCredibilityFactor(
                      'Stable Employment',
                      'I am currently employed or have a stable source of income',
                      _hasEmployment,
                      (value) => setState(() => _hasEmployment = value),
                    ),
                    const SizedBox(height: 12),

                    _buildCredibilityFactor(
                      'Bank Account',
                      'I have an active bank account',
                      _hasBankAccount,
                      (value) => setState(() => _hasBankAccount = value),
                    ),
                    const SizedBox(height: 12),

                    _buildCredibilityFactor(
                      'Good Credit History',
                      'I have no outstanding debts or bad credit history',
                      _hasGoodCreditHistory,
                      (value) => setState(() => _hasGoodCreditHistory = value),
                    ),
                    const SizedBox(height: 12),

                    _buildCredibilityFactor(
                      'Collateral Available',
                      'I have assets that can be used as collateral',
                      _hasCollateral,
                      (value) => setState(() => _hasCollateral = value),
                    ),
                    const SizedBox(height: 24),

                    // Income Range
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Annual Income Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select your approximate annual income range',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButton<int>(
                              value: _incomeRange,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Less than ₱20,000')),
                                DropdownMenuItem(value: 1, child: Text('₱20,000 - ₱50,000')),
                                DropdownMenuItem(value: 2, child: Text('₱50,000 - ₱100,000')),
                                DropdownMenuItem(value: 3, child: Text('More than ₱100,000')),
                              ],
                              onChanged: (value) => setState(() => _incomeRange = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateCredibility,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Saving to Database...'),
                                ],
                              )
                            : const Text(
                                'Update Credibility Score',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preview new score
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Projected New Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_calculateScore()} / 100',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Based on your current selections',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Unsaved changes indicator
                    if (_hasUnsavedChanges) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You have unsaved changes',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}