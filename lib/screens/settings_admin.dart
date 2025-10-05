// lib/screens/settings_admin.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late AdminSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedCategory = 'System';

  // Controllers for text fields
  final _appNameController = TextEditingController();
  final _colorAccentController = TextEditingController();

  final List<String> _categories = [
    'System',
    'Appearance & Branding',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _colorAccentController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadAdminSettings();
      setState(() {
        _settings = settings;
        _appNameController.text = settings.appName;
        _colorAccentController.text = settings.colorAccent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = SettingsDefaults.getDefaultAdminSettings();
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load settings');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final success = await SettingsService.saveAdminSettings(_settings);
      
      if (success) {
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



  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        _showSuccessSnackBar('Logo upload stubbed - file selected: ${result.files.first.name}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick logo');
    }
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
        title: const Text('Admin Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar with categories
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(right: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: ListView(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                  title: Text(
                    category,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCategoryContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'System':
        return _buildSystemSection();
      case 'Appearance & Branding':
        return _buildAppearanceSection();
      default:
        return const Center(child: Text('Select a category'));
    }
  }

  Widget _buildSystemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Maintenance Mode'),
                  subtitle: const Text('Enable maintenance mode. Users will be prevented from making changes.'),
                  value: _settings.maintenanceMode,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        maintenanceMode: value,
                        lastMaintenanceToggle: DateTime.now(),
                      );
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('App Version'),
                  subtitle: Text(_settings.appVersion),
                  trailing: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
        ),
        // Last change log
        if (_settings.lastMaintenanceToggle != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Change',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maintenance mode toggled: ${_settings.lastMaintenanceToggle!.toString()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }







  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance & Branding',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primary,
                      child: _settings.logoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _settings.logoUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 30, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.image, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _appNameController,
                            decoration: const InputDecoration(
                              labelText: 'App Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(appName: value);
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload Logo'),
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
                TextField(
                  controller: _colorAccentController,
                  decoration: const InputDecoration(
                    labelText: 'Color Accent (Hex)',
                    border: OutlineInputBorder(),
                    helperText: 'Enter hex color code (e.g., #0B6E4F)',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(colorAccent: value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
