# Settings System Implementation

This document provides instructions for integrating the new Settings UI into your Flutter project.

## Files Added

- `lib/models/settings_model.dart` - Data models for user and admin settings with JSON serialization
- `lib/services/settings_service.dart` - Service for saving/loading settings with Firestore and local fallback
- `lib/screens/settings_user.dart` - User settings screen with expandable sections
- `lib/screens/settings_admin.dart` - Admin settings screen with sidebar navigation

## Integration Steps

### 1. Add Dependencies

Add these dependencies to your `pubspec.yaml` if not already present:

```yaml
dependencies:
  shared_preferences: ^2.2.2
  file_picker: ^6.1.1
```

Then run:
```bash
flutter pub get
```

### 2. Update main.dart

Add the new routes to your `main.dart`:

```dart
// Add these imports
import 'package:flutter_project_final/screens/settings_user.dart';
import 'package:flutter_project_final/screens/settings_admin.dart';

// Add these routes to your routes map
routes: {
  '/login': (_) => const LoginScreen(),
  '/signup': (_) => const SignupScreen(),
  '/userDashboard': (_) => const HomeScreen(),
  '/adminDashboard': (_) => const AdminDashboard(),
  '/userloan': (_) => const LoanPage(),
  '/userpayment': (_) => const PaymentPage(),
  '/userhistory': (_) => const UserHistoryPage(),
  '/LoanApplicationsPage': (_) => const LoanApplicationsPage(),
  '/adminHistory': (_) => const AdminHistoryPage(),
  '/userloanstatus': (_) => const UserLoanStatusPage(),
  // Add these new routes
  '/userSettings': (_) => const UserSettingsScreen(),
  '/adminSettings': (_) => const AdminSettingsScreen(),
},
```

### 3. Add Navigation Links

Add settings navigation to your existing screens:

**For User Dashboard (`lib/screens/userhome.dart`):**
```dart
// Add to your AppBar actions or drawer
IconButton(
  onPressed: () => Navigator.pushNamed(context, '/userSettings'),
  icon: const Icon(Icons.settings),
)
```

**For Admin Dashboard (`lib/screens/admin_dashboard.dart`):**
```dart
// Add to your AppBar actions or drawer
IconButton(
  onPressed: () => Navigator.pushNamed(context, '/adminSettings'),
  icon: const Icon(Icons.settings),
)
```

### 4. Seed Default Settings (Optional)

To populate Firestore with default settings, call this once during app initialization:

```dart
// In your main() function or app initialization
await SettingsService.seedDefaultSettings();
```

### 5. Test the Settings Screens

**User Settings:**
1. Navigate to `/userSettings`
2. Test form validation (display name is required)
3. Try toggling switches and changing dropdowns
4. Test the save functionality
5. Verify success/error messages

**Admin Settings:**
1. Navigate to `/adminSettings`
2. Test sidebar navigation between categories
3. Try toggling maintenance mode
4. Test form inputs and validation
5. Verify save functionality

## Features Implemented

### User Settings
- ✅ Profile section with avatar upload (stubbed) and display name
- ✅ Account & Security with email (readonly), password change, 2FA, auto-logout
- ✅ Notifications with push, email receipts, payment reminders
- ✅ Payments with default method, auto-pay, save card options
- ✅ Loan preferences with due dates, admin updates, statement view
- ✅ Privacy & Data with usage sharing, data download, account deletion
- ✅ Appearance & Accessibility with theme and text size options
- ✅ Help & Legal with support and policy links

### Admin Settings
- ✅ System settings with maintenance mode, app version, force logout
- ✅ User Management with invite functionality and user list
- ✅ Loan Workflow with auto-approve threshold and max loans
- ✅ Payments & Reconciliation with manual edits and CSV export
- ✅ Notifications & Templates with email templates and thresholds
- ✅ Security & Audit with 2FA requirement and IP whitelist
- ✅ Integrations with payment gateway configuration
- ✅ Appearance & Branding with app name, logo, and color settings

## Data Persistence

The settings system uses a hybrid approach:
1. **Primary**: Firestore (if available and user is authenticated)
2. **Fallback**: SharedPreferences (local storage)

Settings are cached in memory to avoid repeated reads.

## Security Notes

⚠️ **Important**: The admin role check is client-side only. In production, you must implement server-side validation and Firestore security rules to prevent unauthorized access to admin settings.

## Customization

You can easily customize:
- Default values in `SettingsDefaults` class
- UI styling by modifying the theme usage
- Additional settings fields by extending the models
- Validation rules in the form fields

## Troubleshooting

1. **Settings not saving**: Check Firestore permissions and authentication status
2. **UI not loading**: Verify all dependencies are installed
3. **Navigation errors**: Ensure routes are properly added to main.dart
4. **File picker issues**: Check platform-specific permissions for file access
