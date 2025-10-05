# QA Checklist for UI Refresh Implementation

## Pre-Testing Setup
- [ ] Ensure `NEW_UI_ENABLED = true` in `lib/main.dart`
- [ ] Run `flutter pub get` to install dependencies
- [ ] Build the app: `flutter build web`

## Feature Flag Testing
- [ ] **Rollback Test**: Set `NEW_UI_ENABLED = false` in `lib/main.dart`
  - [ ] App compiles and runs without errors
  - [ ] UI appears identical to original (green theme, original styling)
  - [ ] All existing functionality works as before
- [ ] **New UI Test**: Set `NEW_UI_ENABLED = true` in `lib/main.dart`
  - [ ] App compiles and runs without errors
  - [ ] New theme is applied (dark green primary color)
  - [ ] All existing functionality works with new theme

## New Widget Testing
- [ ] **LoanCard Widget**
  - [ ] Can be instantiated with required parameters
  - [ ] Displays loan information correctly
  - [ ] Shows proper status colors (active=green, late=orange, closed=grey)
  - [ ] Handles tap events when onTap callback provided
  - [ ] Formats currency correctly with ₱ symbol

- [ ] **Loading Dialog**
  - [ ] `showLoading()` displays dialog with spinner and text
  - [ ] Dialog is not dismissible by tapping outside
  - [ ] `hideLoading()` closes the dialog properly
  - [ ] Custom loading text is displayed when provided

- [ ] **ApplyStepper Screen**
  - [ ] Displays 3-step process (Details, Review, Docs)
  - [ ] Step indicators show current step correctly
  - [ ] Navigation between steps works (Next/Back buttons)
  - [ ] Form validation works on each step

## Form Validation Testing
- [ ] **Details Step Validation**
  - [ ] Empty amount field shows "Enter amount" error
  - [ ] Empty term field shows "Enter term" error
  - [ ] Invalid number format shows appropriate error
  - [ ] Zero or negative amounts show validation error
  - [ ] Valid inputs allow progression to next step

- [ ] **Review Step**
  - [ ] Displays entered amount and term
  - [ ] Shows estimated calculations (placeholder text)
  - [ ] Allows progression to final step

- [ ] **Docs Step**
  - [ ] Displays upload instructions
  - [ ] Upload button is present and functional
  - [ ] Submit button appears on final step

## Integration Testing
- [ ] **LoanService Integration**
  - [ ] ApplyStepper calls `LoanService.submitApplication()` on submit
  - [ ] Loading dialog appears during submission
  - [ ] Success: Dialog closes and stepper exits
  - [ ] Error: Error message displayed in SnackBar
  - [ ] All async operations check `mounted` before Navigator calls

## Error Handling Testing
- [ ] **Network Failure Simulation**
  - [ ] Mock LoanService to throw exception
  - [ ] Verify error SnackBar appears
  - [ ] Verify app doesn't crash
  - [ ] Verify loading dialog closes properly

- [ ] **Navigation Safety**
  - [ ] All Navigator calls check `mounted` state
  - [ ] No crashes when navigating after widget disposal

## Performance Testing
- [ ] **Build Performance**
  - [ ] Web build completes successfully
  - [ ] Build time is reasonable (< 60 seconds)
  - [ ] No memory leaks in widget creation

- [ ] **Runtime Performance**
  - [ ] App launches quickly
  - [ ] Theme switching is smooth
  - [ ] Widget rendering is efficient

## Backward Compatibility Testing
- [ ] **Existing Routes**
  - [ ] All existing routes work unchanged
  - [ ] Navigation between screens works
  - [ ] Deep linking still functions

- [ ] **Data Models**
  - [ ] No changes to existing data structures
  - [ ] Firebase integration unchanged
  - [ ] Authentication flow unchanged

## Cross-Platform Testing
- [ ] **Web Platform**
  - [ ] App runs in Chrome/Firefox/Safari
  - [ ] Responsive design works
  - [ ] Touch interactions work on mobile browsers

- [ ] **Mobile Platforms** (if applicable)
  - [ ] Android build works
  - [ ] iOS build works
  - [ ] Native platform features unaffected

## Code Quality Checks
- [ ] **Linting**
  - [ ] No linter errors or warnings
  - [ ] Code follows Flutter best practices
  - [ ] Proper error handling implemented

- [ ] **Testing**
  - [ ] Unit tests pass: `flutter test test/unit/`
  - [ ] Widget tests pass: `flutter test test/widget/`
  - [ ] Test coverage is adequate

## Final Verification
- [ ] **Production Readiness**
  - [ ] Feature flag can be toggled safely
  - [ ] No breaking changes introduced
  - [ ] Documentation updated if needed
  - [ ] Ready for deployment

## Rollback Plan
- [ ] **Emergency Rollback**
  - [ ] Set `NEW_UI_ENABLED = false`
  - [ ] Verify app returns to original state
  - [ ] No data loss or corruption
  - [ ] All features remain functional

---

**Test Results Summary:**
- [ ] All tests passed
- [ ] No critical issues found
- [ ] Ready for production deployment
- [ ] Rollback plan verified

**Tester:** _________________  
**Date:** _________________  
**Version:** _________________

