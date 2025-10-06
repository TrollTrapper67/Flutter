// =============================================================================
// FLUTTER AFFORDABILITY CALCULATOR - Core Logic Functions
// =============================================================================

import 'dart:math';

class AffordabilityConfig {
  static const double affordabilityThreshold = 0.40; // 40% DTI threshold
  static const int minimumJobTenureMonths = 3; // Minimum job tenure
  static const double annualRatePercent = 12.0; // Default annual interest rate
  static const String currency = 'PHP'; // Currency symbol ₱
}

class AffordabilityStrings {
  static const String title = "Quick affordability check";
  static const String subtitle =
      "We use these to estimate affordability. This is a soft check and not a hard credit inquiry.";

  // Field labels
  static const String employmentStatus = "Employment status";
  static const String monthlyIncome = "Monthly net income";
  static const String monthlyObligations = "Monthly obligations";
  static const String jobTenure = "Job tenure (months)";
  static const String uploadPayslip = "Upload payslip";

  // Employment options
  static const Map<String, String> employmentOptions = {
    "employed": "Employed",
    "government": "Government Employee",
    "self-employed": "Self-employed",
    "unemployed": "Unemployed",
    "student": "Student",
  };

  // Buttons
  static const String estimateNow = "Estimate now";
  static const String skipContinue = "Skip and continue to full application";
  static const String confirmContinue = "Confirm and continue";

  // Help text
  static const String incomeHelp =
      "Enter your net monthly income and current monthly obligations. This takes 30 seconds and helps us estimate if the loan fits your budget.";
  static const String privacyNote =
      "We only use this to estimate affordability. This is a soft check and won't affect your credit score.";

  // Verdict messages
  static String likelyEligible(double monthlyPayment) =>
      "Likely eligible — you can afford ₱${formatCurrency(monthlyPayment)}/month for this loan.";

  static String needsReview(String reason) =>
      "Needs review — $reason. We'll review your application.";

  static String notRecommended(double dti) =>
      "Not recommended — current obligations leave little room for extra payments (DTI: ${(dti * 100).toStringAsFixed(1)}%).";

  // Format currency helper
  static String formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return "0.00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  // Format currency input (for text fields)
  static String formatCurrencyInput(String input) {
    // Remove all non-digits and decimal points
    String cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');

    // If empty, return empty
    if (cleaned.isEmpty) return '';

    // Split by decimal point
    List<String> parts = cleaned.split('.');

    // Add commas to the integer part
    if (parts.isNotEmpty) {
      String integerPart = parts[0];
      String formatted = integerPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

      // Rejoin with decimal part if it exists
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return '$formatted.${parts[1]}';
      }
      return formatted;
    }

    return cleaned;
  }
}

// =============================================================================
// CORE CALCULATION FUNCTIONS (Pure functions for server-side compatibility)
// =============================================================================

class AffordabilityCalculator {
  /// Calculate Debt-to-Income ratio
  static double computeDTI(double monthlyObligations, double monthlyIncome) {
    if (monthlyIncome <= 0) return double.infinity;
    return monthlyObligations / monthlyIncome;
  }

  /// Calculate allowed monthly payment based on affordability
  static double computeAllowedMonthly(
    double monthlyIncome,
    double monthlyObligations,
  ) {
    final threshold =
        monthlyIncome * AffordabilityConfig.affordabilityThreshold;
    return threshold - monthlyObligations > 0
        ? threshold - monthlyObligations
        : 0;
  }

  /// Calculate monthly payment for amortized loan
  static double computeMonthlyPaymentAmortized(
    double principal,
    int months, {
    double annualRatePercent = AffordabilityConfig.annualRatePercent,
  }) {
    if (principal <= 0 || months <= 0) return 0;

    final r = annualRatePercent / 100 / 12; // Monthly interest rate
    final numerator = principal * r;
    final denominator = 1 - pow(1 + r, -months);

    return denominator != 0 ? numerator / denominator : 0;
  }

  /// Calculate monthly payment for zero-interest loan
  static double computeMonthlyPaymentZeroInterest(
    double principal,
    int months,
  ) {
    if (principal <= 0 || months <= 0) return 0;
    return principal / months;
  }

  /// Calculate maximum principal for afford-based loan (zero interest)
  static double computeMaxPrincipalZeroInterest(
    double allowedMonthly,
    int months,
  ) {
    if (allowedMonthly <= 0 || months <= 0) return 0;
    return allowedMonthly * months;
  }

  /// Calculate maximum principal for afford-based loan (with interest)
  static double computeMaxPrincipalAmortized(
    double allowedMonthly,
    int months, {
    double annualRatePercent = AffordabilityConfig.annualRatePercent,
  }) {
    if (allowedMonthly <= 0 || months <= 0) return 0;

    final r = annualRatePercent / 100 / 12; // Monthly interest rate
    final numerator = allowedMonthly * (1 - pow(1 + r, -months));

    return r != 0 ? numerator / r : allowedMonthly * months;
  }

  /// Determine loan eligibility verdict
  static AffordabilityVerdict decideVerdict({
    required double monthlyIncome,
    required double monthlyObligations,
    double estimatedMonthlyPayment = 0,
    int jobTenureMonths = 0,
    String employmentStatus = 'employed',
  }) {
    // Calculate core metrics
    final dti = computeDTI(monthlyObligations, monthlyIncome);
    final allowedMonthly = computeAllowedMonthly(
      monthlyIncome,
      monthlyObligations,
    );

    // Job tenure check
    final hasShortTenure =
        employmentStatus == 'employed' &&
        jobTenureMonths > 0 &&
        jobTenureMonths < AffordabilityConfig.minimumJobTenureMonths;

    // Main eligibility logic
    if (dti <= AffordabilityConfig.affordabilityThreshold &&
        allowedMonthly >= estimatedMonthlyPayment) {
      final reason = hasShortTenure ? "short job tenure" : "";
      return AffordabilityVerdict(
        status: hasShortTenure
            ? AffordabilityStatus.needsReview
            : AffordabilityStatus.likelyEligible,
        reason: reason,
        suggestedAction: hasShortTenure ? 'continue_with_review' : 'approve',
        dti: dti,
        allowedMonthly: allowedMonthly,
        estimatedMonthlyPayment: estimatedMonthlyPayment,
        employmentStatus: employmentStatus,
        jobTenureMonths: jobTenureMonths,
      );
    }

    if (dti <= 0.6) {
      final reasons = <String>[];
      if (hasShortTenure) reasons.add("short job tenure");
      if (allowedMonthly < estimatedMonthlyPayment) {
        final shortfall = estimatedMonthlyPayment - allowedMonthly;
        reasons.add(
          "insufficient affordability (gap: ₱${AffordabilityStrings.formatCurrency(shortfall)})",
        );
      }

      return AffordabilityVerdict(
        status: AffordabilityStatus.needsReview,
        reason: reasons.join(" and "),
        suggestedAction: 'manual_review',
        dti: dti,
        allowedMonthly: allowedMonthly,
        estimatedMonthlyPayment: estimatedMonthlyPayment,
        employmentStatus: employmentStatus,
        jobTenureMonths: jobTenureMonths,
      );
    }

    return AffordabilityVerdict(
      status: AffordabilityStatus.notRecommended,
      reason:
          "DTI ${(dti * 100).toStringAsFixed(1)}% exceeds ${(AffordabilityConfig.affordabilityThreshold * 100).toStringAsFixed(0)}% threshold",
      suggestedAction: 'decline',
      dti: dti,
      allowedMonthly: allowedMonthly,
      estimatedMonthlyPayment: estimatedMonthlyPayment,
      employmentStatus: employmentStatus,
      jobTenureMonths: jobTenureMonths,
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

enum AffordabilityStatus { likelyEligible, needsReview, notRecommended }

class AffordabilityVerdict {
  final AffordabilityStatus status;
  final String reason;
  final String suggestedAction;
  final double dti;
  final double allowedMonthly;
  final double estimatedMonthlyPayment;
  final String employmentStatus;
  final int jobTenureMonths;

  const AffordabilityVerdict({
    required this.status,
    required this.reason,
    required this.suggestedAction,
    required this.dti,
    required this.allowedMonthly,
    required this.estimatedMonthlyPayment,
    required this.employmentStatus,
    required this.jobTenureMonths,
  });

  String get statusDisplay {
    switch (status) {
      case AffordabilityStatus.likelyEligible:
        return "✅ Likely Eligible";
      case AffordabilityStatus.needsReview:
        return "⚠️ Needs Review";
      case AffordabilityStatus.notRecommended:
        return "❌ Not Recommended";
    }
  }

  String get statusMessage {
    switch (status) {
      case AffordabilityStatus.likelyEligible:
        return AffordabilityStrings.likelyEligible(estimatedMonthlyPayment);
      case AffordabilityStatus.needsReview:
        return AffordabilityStrings.needsReview(reason);
      case AffordabilityStatus.notRecommended:
        return AffordabilityStrings.notRecommended(dti);
    }
  }
}