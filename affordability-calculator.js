// =============================================================================
// AFFORDABILITY CALCULATOR - Core Logic Functions
// =============================================================================

// Configuration constants
const CONFIG = {
  affordabilityThreshold: 0.40, // 40% DTI threshold
  minimumJobTenureMonths: 3,     // Minimum job tenure
  annualRatePercent: 12.0,       // Default annual interest rate
  currency: 'PHP',               // Currency symbol ₱
};

// Microcopy strings for internationalization
const STRINGS = {
  title: "Quick affordability check",
  subtitle: "We use these to estimate affordability. This is a soft check and not a hard credit inquiry.",
  
  // Field labels
  employmentStatus: "Employment status",
  monthlyIncome: "Monthly net income",
  monthlyObligations: "Monthly obligations",
  jobTenure: "Job tenure (months)",
  uploadPayslip: "Upload payslip",
  
  // Employment options
  employmentOptions: [
    { value: "employed", label: "Employed" },
    { value: "government", label: "Government Employee" },
    { value: "self-employed", label: "Self-employed" },
    { value: "unemployed", label: "Unemployed" },
    { value: "student", label: "Student" }
  ],
  
  // Buttons
  estimateNow: "Estimate now",
  skipContinue: "Skip and continue to full application",
  confirmContinue: "Confirm and continue",
  
  // Verdict messages
  likelyEligible: (principal, monthlyPayment) => 
    `Likely eligible — you can afford ₱${formatCurrency(monthlyPayment)}/month for ${principal > 0 ? 'this loan' : 'the requested term'}.`,
  
  needsReview: (reason = "") => 
    `Needs review — ${reason.trim()}. We'll review your application.`,
  
  notRecommended: (dti) => 
    `Not recommended — current obligations leave little room for extra payments (DTI: ${(dti * 100).toFixed(1)}%).`,
  
  // Help text
  incomeHelp: "Enter your net monthly income and current monthly obligations. This takes 30 seconds and helps us estimate if the loan fits your budget.",
  privacyNote: "We only use this to estimate affordability. This is a soft check and won't affect your credit score.",
};

// Format currency helper
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-PH', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount || 0);
}

// =============================================================================
// CORE CALCULATION FUNCTIONS (Pure functions for server-side compatibility)
// =============================================================================

/**
 * Calculate Debt-to-Income ratio
 * @param {number} monthlyObligations - Monthly debt payments
 * @param {number} monthlyIncome - Monthly gross income
 * @returns {number} DTI ratio (0-1 or higher)
 */
function computeDTI(monthlyObligations, monthlyIncome) {
  if (!monthlyIncome || monthlyIncome <= 0) return Infinity;
  return monthlyObligations / monthlyIncome;
}

/**
 * Calculate allowed monthly payment based on affordability
 * @param {number} monthlyIncome - Monthly income
 * @param {number} monthlyObligations - Current debt payments
 * @returns {number} Maximum affordable monthly payment
 */
function computeAllowedMonthly(monthlyIncome, monthlyObligations) {
  const threshold = monthlyIncome * CONFIG.affordabilityThreshold;
  return Math.max(0, threshold - monthlyObligations);
}

/**
 * Calculate monthly payment for amortized loan
 * @param {number} principal - Loan amount
 * @param {number} months - Loan term in months
 * @param {number} annualRatePercent - Annual interest rate
 * @returns {number} Monthly payment amount
 */
function computeMonthlyPaymentAmortized(principal, months, annualRatePercent = CONFIG.annualRatePercent) {
  if (!principal || principal <= 0 || !months || months <= 0) return 0;
  
  const r = annualRatePercent / 100 / 12; // Monthly interest rate
  const numerator = principal * r;
  const denominator = 1 - Math.pow(1 + r, -months);
  
  return denominator !== 0 ? numerator / denominator : 0;
}

/**
 * Calculate monthly payment for zero-interest loan
 * @param {number} principal - Loan amount
 * @param {number} months - Loan term in months
 * @returns {number} Monthly payment amount
 */
function computeMonthlyPaymentZeroInterest(principal, months) {
  if (!principal || principal <= 0 || !months || months <= 0) return 0;
  return principal / months;
}

/**
 * Calculate maximum principal for afford-based loan (zero interest)
 * @param {number} allowedMonthly - Maximum affordable monthly payment
 * @param {number} months - Loan term in months
 * @returns {number} Maximum principal amount
 */
function computeMaxPrincipalZeroInterest(allowedMonthly, months) {
  if (!allowedMonthly || allowedMonthly <= 0 || !months || months <= 0) return 0;
  return allowedMonthly * months;
}

/**
 * Calculate maximum principal for afford-based loan (with interest)
 * @param {number} allowedMonthly - Maximum affordable monthly payment
 * @param {number} months - Loan term in months
 * @param {number} annualRatePercent - Annual interest rate
 * @returns {number} Maximum principal amount
 */
function computeMaxPrincipalAmortized(allowedMonthly, months, annualRatePercent = CONFIG.annualRatePercent) {
  if (!allowedMonthly || allowedMonthly <= 0 || !months || months <= 0) return 0;
  
  const r = annualRatePercent / 100 / 12; // Monthly interest rate
  const numerator = allowedMonthly * (1 - Math.pow(1 + r, -months));
  
  return r !== 0 ? numerator / r : allowedMonthly * months;
}

/**
 * Determine loan eligibility verdict
 * @param {Object} params - Eligibility parameters
 * @param {number} params.monthlyIncome - Monthly income
 * @param {number} params.monthlyObligations - Monthly debt payments
 * @param {number} params.estimatedMonthlyPayment - Proposed monthly payment
 * @param {number} params.jobTenureMonths - Job tenure in months
 * @param {string} params.employmentStatus - Employment status
 * @returns {Object} Verdict with status, reason, and calculations
 */
function decideVerdict({
  monthlyIncome,
  monthlyObligations,
  estimatedMonthlyPayment,
  jobTenureMonths = 0,
  employmentStatus = 'employed'
}) {
  // Calculate core metrics
  const dti = computeDTI(monthlyObligations, monthlyIncome);
  const allowedMonthly = computeAllowedMonthly(monthlyIncome, monthlyObligations);
  
  const baseMetrics = {
    dti,
    allowedMonthly,
    employmentStatus,
    jobTenureMonths,
    estimatedMonthlyPayment: estimatedMonthlyPayment || 0
  };
  
  // Job tenure check
  const hasShortTenure = employmentStatus === 'employed' && 
                        jobTenureMonths > 0 && 
                        jobTenureMonths < CONFIG.minimumJobTenureMonths;
  
  // Main eligibility logic
  if (dti <= CONFIG.affordabilityThreshold && allowedMonthly >= estimatedMonthlyPayment) {
    const reason = hasShortTenure ? "short job tenure" : "";
    return {
      status: hasShortTenure ? 'needs_review' : 'likely_eligible',
      reason: reason,
      suggestedAction: hasShortTenure ? 'continue_with_review' : 'approve',
      ...baseMetrics
    };
  }
  
  if (dti <= 0.6) {
    const reasons = [];
    if (hasShortTenure) reasons.push("short job tenure");
    if (allowedMonthly < estimatedMonthlyPayment) {
      const shortfall = estimatedMonthlyPayment - allowedMonthly;
      reasons.push(`insufficient affordability (gap: ₱${formatCurrency(shortfall)})`);
    }
    
    return {
      status: 'needs_review',
      reason: reasons.join(" and ");
      suggestedAction: 'manual_review',
      ...baseMetrics
    };
  }
  
  return {
    status: 'not_recommended',
    reason: `DTI ${(dti * 100).toFixed(1)}% exceeds ${(CONFIG.affordabilityThreshold * 100)}% threshold`,
    suggestedAction: 'decline',
    ...baseMetrics
  };
}

// =============================================================================
// EXPORTS
// =============================================================================

if (typeof module !== 'undefined' && module.exports) {
  // Node.js exports
  module.exports = {
    CONFIG,
    STRINGS,
    formatCurrency,
    computeDTI,
    computeAllowedMonthly,
    computeMonthlyPaymentAmortized,
    computeMonthlyPaymentZeroInterest,
    computeMaxPrincipalZeroInterest,
    computeMaxPrincipalAmortized,
    decideVerdict
  };
} else {
  // Browser global
  window.AffordabilityCalculator = {
    CONFIG,
    STRINGS,
    formatCurrency,
    computeDTI,
    computeAllowedMonthly,
    computeMonthlyPaymentAmortized,
    computeMonthlyPaymentZeroInterest,
    computeMaxPrincipalZeroInterest,
    computeMaxPrincipalAmortized,
    decideVerdict
  };
}
