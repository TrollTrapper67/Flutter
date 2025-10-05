// lib/services/loan_service.dart
// Mock service to prevent compilation errors
class LoanService {
  static Future<void> submitApplication(String userId, Map<String, dynamic> form) async {
    // Mock implementation - replace with actual service call
    await Future.delayed(const Duration(seconds: 1));
    print('Submitting loan application for user $userId with data: $form');
  }
}

