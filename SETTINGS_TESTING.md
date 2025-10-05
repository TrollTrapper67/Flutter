# Settings System Testing Guide

This guide provides step-by-step instructions for testing the new Settings UI functionality.

## Prerequisites

1. Ensure all dependencies are installed:
   ```bash
   flutter pub get
   ```

2. Make sure Firebase is properly configured and running.

## Testing User Settings

### 1. Navigate to User Settings
1. Launch the app and log in as a regular user
2. From the user dashboard, tap the settings icon (⚙️) in the top-right corner
3. Verify the User Settings screen loads with all sections

### 2. Test Profile Section
1. **Display Name**: 
   - Try entering an empty name (should show validation error)
   - Enter a valid name and verify it saves
2. **Avatar Upload**: 
   - Tap "Upload Avatar" button
   - Select an image file
   - Verify success message appears
3. **Contact Phone**: 
   - Enter a phone number (optional field)
   - Verify it saves correctly

### 3. Test Account & Security Section
1. **Email Field**: 
   - Verify it's read-only and shows current user email
2. **Change Password**: 
   - Tap "Change Password" button
   - Verify dialog appears with placeholder message
3. **Two-Factor Auth**: 
   - Toggle the switch
   - Verify state changes
4. **Auto Logout**: 
   - Change dropdown selection
   - Verify selection updates

### 4. Test Notifications Section
1. **Push Notifications**: Toggle and verify state
2. **Email Receipts**: Toggle and verify state
3. **Payment Reminders**: 
   - Toggle and verify state
   - When enabled, verify "Reminder Days" dropdown appears
   - Test different day selections

### 5. Test Payments Section
1. **Default Payment Method**: Change dropdown selection
2. **Auto-Pay**: Toggle switch
3. **Save Card**: Toggle switch

### 6. Test Loan Preferences Section
1. **Show Upcoming Due Dates**: Toggle switch
2. **Notify for Admin Updates**: Toggle switch
3. **Preferred Statement View**: Change dropdown selection

### 7. Test Privacy & Data Section
1. **Share Usage Data**: Toggle switch
2. **Download My Data**: Tap button, verify error message
3. **Delete Account**: Tap button, verify confirmation dialog

### 8. Test Appearance & Accessibility Section
1. **Theme**: Change between System/Light/Dark
2. **Text Size**: Change between Small/Normal/Large

### 9. Test Help & Legal Section
1. Tap each link and verify appropriate messages appear

### 10. Test Save Functionality
1. Make several changes across different sections
2. Tap the "Save" floating action button
3. Verify "Settings saved." message appears
4. Navigate away and back to verify changes persist

## Testing Admin Settings

### 1. Navigate to Admin Settings
1. Log in as an admin user
2. Open the drawer menu (hamburger icon)
3. Tap "Admin Settings"
4. Verify the admin settings screen loads with sidebar navigation

### 2. Test System Section
1. **Maintenance Mode**: 
   - Toggle the switch
   - Verify "Last Change" log appears below
2. **App Version**: Verify it displays current version
3. **Force Logout**: Tap button, verify confirmation dialog

### 3. Test User Management Section
1. **Invite User**: 
   - Enter an email address
   - Tap "Invite" button
   - Verify user appears in the list
   - Test removing a user from the list

### 4. Test Loan Workflow Section
1. **Auto-Approve Threshold**: 
   - Enter a number
   - Verify it updates
   - Clear field to disable auto-approval
2. **Max Concurrent Loans**: Enter a number and verify

### 5. Test Payments & Reconciliation Section
1. **Allow Manual Balance Edits**: Toggle switch
2. **Reconcile Timer**: Enter number of days
3. **Export Payments CSV**: Tap button, verify error message

### 6. Test Notifications & Templates Section
1. **Notification Failure Threshold**: Enter a number
2. Verify email templates section shows placeholder text

### 7. Test Security & Audit Section
1. **Admin 2FA Requirement**: Toggle switch
2. **IP Whitelist**: 
   - Enter multiple IP addresses (one per line)
   - Verify they save correctly

### 8. Test Integrations Section
1. **Use Live Payment Gateway**: Toggle switch
2. Verify payment gateway config shows placeholder

### 9. Test Appearance & Branding Section
1. **App Name**: Change the name
2. **Upload Logo**: Tap button, select image, verify message
3. **Color Accent**: Enter hex color code

### 10. Test Save Functionality
1. Make changes across different sections
2. Tap the save icon in the app bar
3. Verify "Settings saved." message appears
4. Navigate between sections to verify changes persist

## Testing Data Persistence

### 1. Test Firestore Integration
1. Ensure Firebase is connected
2. Make settings changes and save
3. Check Firestore console for:
   - `settings/users/user_settings/{uid}` for user settings
   - `settings/admin/admin_settings/main` for admin settings

### 2. Test Local Fallback
1. Disconnect from internet
2. Make settings changes
3. Verify they save to local storage
4. Reconnect and verify settings sync

## Testing Error Handling

### 1. Test Network Errors
1. Disconnect from internet
2. Try to save settings
3. Verify appropriate error messages appear

### 2. Test Validation Errors
1. Try to save user settings with empty display name
2. Verify validation error appears
3. Fix the error and verify save succeeds

### 3. Test Authentication Errors
1. Log out while on settings screen
2. Try to save settings
3. Verify appropriate error handling

## Expected Results

### User Settings
- ✅ All form fields work correctly
- ✅ Validation prevents saving invalid data
- ✅ Settings persist after app restart
- ✅ Success/error messages appear appropriately
- ✅ File picker works for avatar upload
- ✅ All toggles and dropdowns function properly

### Admin Settings
- ✅ Sidebar navigation works smoothly
- ✅ All sections load and display correctly
- ✅ Form inputs save and persist
- ✅ Confirmation dialogs appear for destructive actions
- ✅ Settings save to both Firestore and local storage
- ✅ Error handling works for network issues

## Troubleshooting

### Common Issues
1. **Settings not saving**: Check Firebase connection and authentication
2. **UI not loading**: Verify all dependencies are installed
3. **Navigation errors**: Ensure routes are properly added to main.dart
4. **File picker not working**: Check platform-specific permissions

### Debug Steps
1. Check console for error messages
2. Verify Firebase configuration
3. Test with different user roles
4. Check network connectivity
5. Verify all required dependencies are installed
