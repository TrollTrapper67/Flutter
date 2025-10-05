// lib/models/settings_model.dart
import 'dart:convert';

/// User settings model with all required fields and JSON serialization
class UserSettings {
  // Profile
  final String displayName;
  final String? avatarUrl;
  final String? contactPhone;

  // Account & Security
  final String email;
  final bool twoFactorAuth;
  final String autoLogout; // '1h', '8h', '24h'

  // Notifications
  final bool pushNotifications;
  final bool emailReceipts;
  final bool paymentReminders;
  final int paymentReminderDays; // 1, 3, or 7

  // Payments
  final String defaultPaymentMethod;
  final bool autoPay;
  final bool saveCard;

  // Loan preferences
  final bool showUpcomingDueDates;
  final bool notifyForAdminUpdates;
  final String preferredStatementView; // 'compact' or 'detailed'

  // Privacy & Data
  final bool shareUsageData;

  // Appearance & Accessibility
  final String theme; // 'system', 'light', 'dark'
  final String textSize; // 'small', 'normal', 'large'

  const UserSettings({
    required this.displayName,
    this.avatarUrl,
    this.contactPhone,
    required this.email,
    this.twoFactorAuth = false,
    this.autoLogout = '24h',
    this.pushNotifications = true,
    this.emailReceipts = true,
    this.paymentReminders = true,
    this.paymentReminderDays = 3,
    this.defaultPaymentMethod = 'card',
    this.autoPay = false,
    this.saveCard = false,
    this.showUpcomingDueDates = true,
    this.notifyForAdminUpdates = true,
    this.preferredStatementView = 'compact',
    this.shareUsageData = false,
    this.theme = 'system',
    this.textSize = 'normal',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      contactPhone: json['contactPhone'],
      email: json['email'] ?? '',
      twoFactorAuth: json['twoFactorAuth'] ?? false,
      autoLogout: json['autoLogout'] ?? '24h',
      pushNotifications: json['pushNotifications'] ?? true,
      emailReceipts: json['emailReceipts'] ?? true,
      paymentReminders: json['paymentReminders'] ?? true,
      paymentReminderDays: json['paymentReminderDays'] ?? 3,
      defaultPaymentMethod: json['defaultPaymentMethod'] ?? 'card',
      autoPay: json['autoPay'] ?? false,
      saveCard: json['saveCard'] ?? false,
      showUpcomingDueDates: json['showUpcomingDueDates'] ?? true,
      notifyForAdminUpdates: json['notifyForAdminUpdates'] ?? true,
      preferredStatementView: json['preferredStatementView'] ?? 'compact',
      shareUsageData: json['shareUsageData'] ?? false,
      theme: json['theme'] ?? 'system',
      textSize: json['textSize'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'contactPhone': contactPhone,
      'email': email,
      'twoFactorAuth': twoFactorAuth,
      'autoLogout': autoLogout,
      'pushNotifications': pushNotifications,
      'emailReceipts': emailReceipts,
      'paymentReminders': paymentReminders,
      'paymentReminderDays': paymentReminderDays,
      'defaultPaymentMethod': defaultPaymentMethod,
      'autoPay': autoPay,
      'saveCard': saveCard,
      'showUpcomingDueDates': showUpcomingDueDates,
      'notifyForAdminUpdates': notifyForAdminUpdates,
      'preferredStatementView': preferredStatementView,
      'shareUsageData': shareUsageData,
      'theme': theme,
      'textSize': textSize,
    };
  }

  UserSettings copyWith({
    String? displayName,
    String? avatarUrl,
    String? contactPhone,
    String? email,
    bool? twoFactorAuth,
    String? autoLogout,
    bool? pushNotifications,
    bool? emailReceipts,
    bool? paymentReminders,
    int? paymentReminderDays,
    String? defaultPaymentMethod,
    bool? autoPay,
    bool? saveCard,
    bool? showUpcomingDueDates,
    bool? notifyForAdminUpdates,
    String? preferredStatementView,
    bool? shareUsageData,
    String? theme,
    String? textSize,
  }) {
    return UserSettings(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      contactPhone: contactPhone ?? this.contactPhone,
      email: email ?? this.email,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      autoLogout: autoLogout ?? this.autoLogout,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailReceipts: emailReceipts ?? this.emailReceipts,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      paymentReminderDays: paymentReminderDays ?? this.paymentReminderDays,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      autoPay: autoPay ?? this.autoPay,
      saveCard: saveCard ?? this.saveCard,
      showUpcomingDueDates: showUpcomingDueDates ?? this.showUpcomingDueDates,
      notifyForAdminUpdates: notifyForAdminUpdates ?? this.notifyForAdminUpdates,
      preferredStatementView: preferredStatementView ?? this.preferredStatementView,
      shareUsageData: shareUsageData ?? this.shareUsageData,
      theme: theme ?? this.theme,
      textSize: textSize ?? this.textSize,
    );
  }
}

/// Admin settings model with all required fields and JSON serialization
class AdminSettings {
  // System
  final bool maintenanceMode;
  final String appVersion;
  final DateTime? lastMaintenanceToggle;

  // User Management
  final List<String> invitedUsers;
  final Map<String, String> userRoles; // userId -> role

  // Loan Workflow
  final double? autoApproveThreshold;
  final Map<String, double> interestRateOverrides; // productId -> rate
  final int maxConcurrentLoansPerUser;

  // Payments & Reconciliation
  final bool allowManualBalanceEdits;
  final int reconcileTimerDays;
  final DateTime? lastReconcileExport;

  // Notifications & Templates
  final Map<String, String> emailTemplates; // templateId -> content
  final int notificationFailureThreshold;

  // Security & Audit
  final bool admin2FARequired;
  final List<Map<String, dynamic>> auditLog;
  final List<String> ipWhitelist;

  // Integrations
  final Map<String, String> paymentGatewayConfig;
  final bool useLivePaymentGateway;

  // Appearance & Branding
  final String appName;
  final String? logoUrl;
  final String colorAccent;

  const AdminSettings({
    this.maintenanceMode = false,
    this.appVersion = '1.0.0',
    this.lastMaintenanceToggle,
    this.invitedUsers = const [],
    this.userRoles = const {},
    this.autoApproveThreshold,
    this.interestRateOverrides = const {},
    this.maxConcurrentLoansPerUser = 3,
    this.allowManualBalanceEdits = false,
    this.reconcileTimerDays = 7,
    this.lastReconcileExport,
    this.emailTemplates = const {},
    this.notificationFailureThreshold = 5,
    this.admin2FARequired = true,
    this.auditLog = const [],
    this.ipWhitelist = const [],
    this.paymentGatewayConfig = const {},
    this.useLivePaymentGateway = false,
    this.appName = 'Midas Touch',
    this.logoUrl,
    this.colorAccent = '#0B6E4F',
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      maintenanceMode: json['maintenanceMode'] ?? false,
      appVersion: json['appVersion'] ?? '1.0.0',
      lastMaintenanceToggle: json['lastMaintenanceToggle'] != null
          ? DateTime.parse(json['lastMaintenanceToggle'])
          : null,
      invitedUsers: List<String>.from(json['invitedUsers'] ?? []),
      userRoles: Map<String, String>.from(json['userRoles'] ?? {}),
      autoApproveThreshold: json['autoApproveThreshold']?.toDouble(),
      interestRateOverrides: Map<String, double>.from(
          json['interestRateOverrides']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {}),
      maxConcurrentLoansPerUser: json['maxConcurrentLoansPerUser'] ?? 3,
      allowManualBalanceEdits: json['allowManualBalanceEdits'] ?? false,
      reconcileTimerDays: json['reconcileTimerDays'] ?? 7,
      lastReconcileExport: json['lastReconcileExport'] != null
          ? DateTime.parse(json['lastReconcileExport'])
          : null,
      emailTemplates: Map<String, String>.from(json['emailTemplates'] ?? {}),
      notificationFailureThreshold: json['notificationFailureThreshold'] ?? 5,
      admin2FARequired: json['admin2FARequired'] ?? true,
      auditLog: List<Map<String, dynamic>>.from(json['auditLog'] ?? []),
      ipWhitelist: List<String>.from(json['ipWhitelist'] ?? []),
      paymentGatewayConfig: Map<String, String>.from(json['paymentGatewayConfig'] ?? {}),
      useLivePaymentGateway: json['useLivePaymentGateway'] ?? false,
      appName: json['appName'] ?? 'Midas Touch',
      logoUrl: json['logoUrl'],
      colorAccent: json['colorAccent'] ?? '#0B6E4F',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceMode': maintenanceMode,
      'appVersion': appVersion,
      'lastMaintenanceToggle': lastMaintenanceToggle?.toIso8601String(),
      'invitedUsers': invitedUsers,
      'userRoles': userRoles,
      'autoApproveThreshold': autoApproveThreshold,
      'interestRateOverrides': interestRateOverrides,
      'maxConcurrentLoansPerUser': maxConcurrentLoansPerUser,
      'allowManualBalanceEdits': allowManualBalanceEdits,
      'reconcileTimerDays': reconcileTimerDays,
      'lastReconcileExport': lastReconcileExport?.toIso8601String(),
      'emailTemplates': emailTemplates,
      'notificationFailureThreshold': notificationFailureThreshold,
      'admin2FARequired': admin2FARequired,
      'auditLog': auditLog,
      'ipWhitelist': ipWhitelist,
      'paymentGatewayConfig': paymentGatewayConfig,
      'useLivePaymentGateway': useLivePaymentGateway,
      'appName': appName,
      'logoUrl': logoUrl,
      'colorAccent': colorAccent,
    };
  }

  AdminSettings copyWith({
    bool? maintenanceMode,
    String? appVersion,
    DateTime? lastMaintenanceToggle,
    List<String>? invitedUsers,
    Map<String, String>? userRoles,
    double? autoApproveThreshold,
    Map<String, double>? interestRateOverrides,
    int? maxConcurrentLoansPerUser,
    bool? allowManualBalanceEdits,
    int? reconcileTimerDays,
    DateTime? lastReconcileExport,
    Map<String, String>? emailTemplates,
    int? notificationFailureThreshold,
    bool? admin2FARequired,
    List<Map<String, dynamic>>? auditLog,
    List<String>? ipWhitelist,
    Map<String, String>? paymentGatewayConfig,
    bool? useLivePaymentGateway,
    String? appName,
    String? logoUrl,
    String? colorAccent,
  }) {
    return AdminSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      appVersion: appVersion ?? this.appVersion,
      lastMaintenanceToggle: lastMaintenanceToggle ?? this.lastMaintenanceToggle,
      invitedUsers: invitedUsers ?? this.invitedUsers,
      userRoles: userRoles ?? this.userRoles,
      autoApproveThreshold: autoApproveThreshold ?? this.autoApproveThreshold,
      interestRateOverrides: interestRateOverrides ?? this.interestRateOverrides,
      maxConcurrentLoansPerUser: maxConcurrentLoansPerUser ?? this.maxConcurrentLoansPerUser,
      allowManualBalanceEdits: allowManualBalanceEdits ?? this.allowManualBalanceEdits,
      reconcileTimerDays: reconcileTimerDays ?? this.reconcileTimerDays,
      lastReconcileExport: lastReconcileExport ?? this.lastReconcileExport,
      emailTemplates: emailTemplates ?? this.emailTemplates,
      notificationFailureThreshold: notificationFailureThreshold ?? this.notificationFailureThreshold,
      admin2FARequired: admin2FARequired ?? this.admin2FARequired,
      auditLog: auditLog ?? this.auditLog,
      ipWhitelist: ipWhitelist ?? this.ipWhitelist,
      paymentGatewayConfig: paymentGatewayConfig ?? this.paymentGatewayConfig,
      useLivePaymentGateway: useLivePaymentGateway ?? this.useLivePaymentGateway,
      appName: appName ?? this.appName,
      logoUrl: logoUrl ?? this.logoUrl,
      colorAccent: colorAccent ?? this.colorAccent,
    );
  }
}

/// Default settings JSON for seeding Firestore or local storage
class SettingsDefaults {
  static const String userSettingsJson = '''
{
  "displayName": "",
  "avatarUrl": null,
  "contactPhone": null,
  "email": "",
  "twoFactorAuth": false,
  "autoLogout": "24h",
  "pushNotifications": true,
  "emailReceipts": true,
  "paymentReminders": true,
  "paymentReminderDays": 3,
  "defaultPaymentMethod": "card",
  "autoPay": false,
  "saveCard": false,
  "showUpcomingDueDates": true,
  "notifyForAdminUpdates": true,
  "preferredStatementView": "compact",
  "shareUsageData": false,
  "theme": "system",
  "textSize": "normal"
}
''';

  static const String adminSettingsJson = '''
{
  "maintenanceMode": false,
  "appVersion": "1.0.0",
  "lastMaintenanceToggle": null,
  "invitedUsers": [],
  "userRoles": {},
  "autoApproveThreshold": null,
  "interestRateOverrides": {},
  "maxConcurrentLoansPerUser": 3,
  "allowManualBalanceEdits": false,
  "reconcileTimerDays": 7,
  "lastReconcileExport": null,
  "emailTemplates": {
    "loan_approved": "Your loan application has been approved!",
    "payment_due": "Payment reminder: Your payment is due soon.",
    "payment_received": "Payment received successfully."
  },
  "notificationFailureThreshold": 5,
  "admin2FARequired": true,
  "auditLog": [],
  "ipWhitelist": [],
  "paymentGatewayConfig": {
    "publicKey": "",
    "secretKey": ""
  },
  "useLivePaymentGateway": false,
  "appName": "Midas Touch",
  "logoUrl": null,
  "colorAccent": "#0B6E4F"
}
''';

  static UserSettings getDefaultUserSettings() {
    return UserSettings.fromJson(jsonDecode(userSettingsJson));
  }

  static AdminSettings getDefaultAdminSettings() {
    return AdminSettings.fromJson(jsonDecode(adminSettingsJson));
  }
}
