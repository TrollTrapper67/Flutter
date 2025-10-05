// lib/screens/settings_user.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  late UserSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _displayNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _contactPhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadUserSettings();
      setState(() {
        _settings = settings;
        _displayNameController.text = settings.displayName;
        _contactPhoneController.text = settings.contactPhone ?? '';
        _emailController.text = settings.email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = SettingsDefaults.getDefaultUserSettings();
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load settings');
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedSettings = _settings.copyWith(
        displayName: _displayNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty 
            ? null 
            : _contactPhoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      final success = await SettingsService.saveUserSettings(updatedSettings);
      
      if (success) {
        setState(() => _settings = updatedSettings);
        _showSuccessSnackBar('Settings saved.');
      } else {
        _showErrorSnackBar('Failed to save settings');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving settings');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        // In a real app, you would upload the file to a storage service
        // For now, we'll just show a message
        _showSuccessSnackBar('Avatar upload stubbed - file selected: ${result.files.first.name}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick avatar');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action is irreversible. Enter password to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showErrorSnackBar('Delete account functionality not implemented');
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Section
              _buildSectionCard(
                title: 'Profile',
                icon: Icons.person,
                children: [
                  // Avatar and Display Name Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary,
                        child: _settings.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _settings.avatarUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 30, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Display name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickAvatar,
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload Avatar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),

              // Account & Security Section
              _buildSectionCard(
                title: 'Account & Security',
                icon: Icons.security,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    readOnly: true,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showChangePasswordDialog,
                  ),
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Add extra security to your account'),
                    value: _settings.twoFactorAuth,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(twoFactorAuth: value);
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.autoLogout,
                    decoration: const InputDecoration(
                      labelText: 'Auto Logout',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1h', child: Text('1 Hour')),
                      DropdownMenuItem(value: '8h', child: Text('8 Hours')),
                      DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(autoLogout: value);
                        });
                      }
                    },
                  ),
                ],
              ),

              // Notifications Section
              _buildSectionCard(
                title: 'Notifications',
                icon: Icons.notifications,
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications on your device'),
                    value: _settings.pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(pushNotifications: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Email Receipts'),
                    subtitle: const Text('Get email receipts for transactions'),
                    value: _settings.emailReceipts,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(emailReceipts: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Payment Reminders'),
                    subtitle: const Text('Get reminded about upcoming payments'),
                    value: _settings.paymentReminders,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(paymentReminders: value);
                      });
                    },
                  ),
                  if (_settings.paymentReminders) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _settings.paymentReminderDays,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Days',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 Day Before')),
                        DropdownMenuItem(value: 3, child: Text('3 Days Before')),
                        DropdownMenuItem(value: 7, child: Text('7 Days Before')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(paymentReminderDays: value);
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),

              // Payments Section
              _buildSectionCard(
                title: 'Payments',
                icon: Icons.payment,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _settings.defaultPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Default Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                      DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'wallet', child: Text('Digital Wallet')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(defaultPaymentMethod: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto-Pay'),
                    subtitle: const Text('Automatically pay bills when due'),
                    value: _settings.autoPay,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(autoPay: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Save Card'),
                    subtitle: const Text('Save payment methods for future use'),
                    value: _settings.saveCard,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(saveCard: value);
                      });
                    },
                  ),
                ],
              ),

              // Loan Preferences Section
              _buildSectionCard(
                title: 'Loan Preferences',
                icon: Icons.account_balance,
                children: [
                  SwitchListTile(
                    title: const Text('Show Upcoming Due Dates'),
                    subtitle: const Text('Display upcoming payment dates on dashboard'),
                    value: _settings.showUpcomingDueDates,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(showUpcomingDueDates: value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notify for Admin Updates'),
                    subtitle: const Text('Get notified when admins update your loan'),
                    value: _settings.notifyForAdminUpdates,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(notifyForAdminUpdates: value);
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.preferredStatementView,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Statement View',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'compact', child: Text('Compact')),
                      DropdownMenuItem(value: 'detailed', child: Text('Detailed')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(preferredStatementView: value);
                        });
                      }
                    },
                  ),
                ],
              ),

              // Privacy & Data Section
              _buildSectionCard(
                title: 'Privacy & Data',
                icon: Icons.privacy_tip,
                children: [
                  SwitchListTile(
                    title: const Text('Share Usage Data'),
                    subtitle: const Text('Help improve the app by sharing anonymous usage data'),
                    value: _settings.shareUsageData,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(shareUsageData: value);
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Download My Data'),
                    trailing: const Icon(Icons.download),
                    onTap: () => _showErrorSnackBar('Download data functionality not implemented'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Delete Account', style: TextStyle(color: AppTheme.danger)),
                    trailing: const Icon(Icons.delete, color: AppTheme.danger),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),

              // Appearance & Accessibility Section
              _buildSectionCard(
                title: 'Appearance & Accessibility',
                icon: Icons.palette,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _settings.theme,
                    decoration: const InputDecoration(
                      labelText: 'Theme',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(theme: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.textSize,
                    decoration: const InputDecoration(
                      labelText: 'Text Size',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'small', child: Text('Small')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'large', child: Text('Large')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(textSize: value);
                        });
                      }
                    },
                  ),
                ],
              ),

              // Help & Legal Section
              _buildSectionCard(
                title: 'Help & Legal',
                icon: Icons.help,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showErrorSnackBar('Contact support functionality not implemented'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showErrorSnackBar('Terms of Service not implemented'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showErrorSnackBar('Privacy Policy not implemented'),
                  ),
                ],
              ),

              const SizedBox(height: 100), // Space for floating action button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSettings,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save'),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
