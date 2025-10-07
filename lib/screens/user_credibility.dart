// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

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

  // Credibility factors - now tracking file paths
  String? _validIDPath;
  String? _employmentProofPath;
  String? _bankStatementPath;
  String? _creditHistoryPath;
  String? _collateralProofPath;
  
  bool get _hasValidID => _validIDPath != null;
  bool get _hasEmployment => _employmentProofPath != null;
  bool get _hasBankAccount => _bankStatementPath != null;
  bool get _hasGoodCreditHistory => _creditHistoryPath != null;
  bool get _hasCollateral => _collateralProofPath != null;
  
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
            
            // Load existing credibility factors
            final factors = data['credibilityFactors'] ?? {};
            final factorsMap = factors is Map<String, dynamic> 
                ? factors 
                : Map<String, dynamic>.from(factors);
            
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

  Future<void> _uploadFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        
        // Simple approach - track file selection without physical storage
        final virtualPath = 'selected://$documentType/$fileName';
        
        setState(() {
          switch (documentType) {
            case 'valid_id_':
              _validIDPath = virtualPath;
              break;
            case 'employment_':
              _employmentProofPath = virtualPath;
              break;
            case 'bank_statement_':
              _bankStatementPath = virtualPath;
              break;
            case 'credit_history_':
              _creditHistoryPath = virtualPath;
              break;
            case 'collateral_':
              _collateralProofPath = virtualPath;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${_getDocumentTypeName(documentType)} selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewFile(String? filePath, String documentType) async {
    if (filePath == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$documentType Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${filePath.split('/').last}'),
            const SizedBox(height: 16),
            Text('Status: Selected for verification', 
                style: TextStyle(color: Colors.green[700])),
            const SizedBox(height: 8),
            const Text('This file will be used for credibility assessment.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
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

  Future<void> _removeFile(String documentType) async {
    setState(() {
      switch (documentType) {
        case 'valid_id':
          _validIDPath = null;
          break;
        case 'employment':
          _employmentProofPath = null;
          break;
        case 'bank_statement':
          _bankStatementPath = null;
          break;
        case 'credit_history':
          _creditHistoryPath = null;
          break;
        case 'collateral':
          _collateralProofPath = null;
          break;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$documentType removed')),
      );
    }
  }

  String _getDocumentTypeName(String documentType) {
    switch (documentType) {
      case 'valid_id_': return 'Valid ID';
      case 'employment_': return 'Employment Proof';
      case 'bank_statement_': return 'Bank Statement';
      case 'credit_history_': return 'Credit History';
      case 'collateral_': return 'Collateral Proof';
      default: return 'Document';
    }
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
          // Store file status (optional - for reference)
          'documentsUploaded': {
            'validID': _hasValidID,
            'employment': _hasEmployment,
            'bankStatement': _hasBankAccount,
            'creditHistory': _hasGoodCreditHistory,
            'collateral': _hasCollateral,
          }
        };
        
        // Save to Firestore
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
              content: Text('✅ Credibility score updated to $_currentScore!'),
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

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    
    return true;
  }

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

  Widget _buildUploadCard(String title, String description, String? filePath, String documentType) {
    final hasFile = filePath != null;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                if (hasFile)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            
            if (hasFile) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File selected: ${filePath.split('/').last}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Ready for verification',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewFile(filePath, title),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removeFile(documentType),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _uploadFile('${documentType}_'),
                  icon: const Icon(Icons.upload),
                  label: const Text('Select Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Supported formats: JPG, PNG, PDF, DOC',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
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
                      'Improve your credibility score by uploading supporting documents:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Upload Cards
                    _buildUploadCard(
                      'Valid Government ID',
                      'Upload a valid government-issued ID (JPG, PNG, PDF)',
                      _validIDPath,
                      'valid_id',
                    ),
                    const SizedBox(height: 12),

                    _buildUploadCard(
                      'Employment Proof',
                      'Upload employment certificate or pay slips',
                      _employmentProofPath,
                      'employment',
                    ),
                    const SizedBox(height: 12),

                    _buildUploadCard(
                      'Bank Statement',
                      'Upload recent bank statements',
                      _bankStatementPath,
                      'bank_statement',
                    ),
                    const SizedBox(height: 12),

                    _buildUploadCard(
                      'Credit History Proof',
                      'Upload credit history documents',
                      _creditHistoryPath,
                      'credit_history',
                    ),
                    const SizedBox(height: 12),

                    _buildUploadCard(
                      'Collateral Proof',
                      'Upload documents for collateral assets',
                      _collateralProofPath,
                      'collateral',
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
                              'Based on your current uploads and selections',
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