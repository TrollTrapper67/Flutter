// =============================================================================
// REACT AFFORDABILITY MODAL COMPONENT
// =============================================================================

import React, { useState, useRef } from 'react';
import { formatCurrency, STRINGS, decideVerdict } from './affordability-calculator.js';

// =============================================================================
// AFFORDABILITY MODAL COMPONENT
// =============================================================================

const AffordabilityModal = ({ 
  isOpen, 
  onClose, 
  onApplyLoan, 
  onSkipToFullApplication,
  currentLoanAmount = 0,
  currentLoanTerm = 12
}) => {
  const modalRef = useRef(null);
  
  // Form state
  const [formData, setFormData] = useState({
    employmentStatus: '',
    monthlyIncome: '',
    monthlyOblrations: '',
    jobTenure: '',
    payslipFiles: []
  });
  
  // UI state
  const [showVerdict, setShowVerdict] = useState(false);
  const [verdict, setVerdict] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  
  // Handle input changes
  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };
  
  // Handle numeric input with currency formatting
  const handleCurrencyInput = (field, value) => {
    const cleanValue = value.replace(/[^\d.]/g, '');
    const numericValue = parseFloat(cleanValue) || '';
    handleInputChange(field, numericValue);
  };
  
  // Handle file upload
  const handlePayslipUpload = (event) => {
    const files = Array.from(event.target.files);
    const imageFiles = files.filter(file => file.type.startsWith('image/'));
    
    setFormData(prev => ({
      ...prev,
      payslipFiles: [...prev.payslipFiles, ...imageFiles]
    }));
  };
  
  // Estimate affordability
  const handleEstimate = async () => {
    if (!formData.monthlyIncome || !formData.monthlyObligations) {
      alert('Please enter both monthly income and obligations');
      return;
    }
    
    setIsLoading(true);
    
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // Calculate estimated monthly payment for current loan
    const estimatedMonthlyPayment = currentLoanAmount > 0 && currentLoanTerm > 0 
      ? currentLoanAmount / currentLoanTerm  // Zero interest for demo
      : 0;
    
    // Get verdict
    const result = decideVerdict({
      monthlyIncome: parseFloat(formData.monthlyIncome),
      monthlyObligations: parseFloat(formData.monthlyObligations),
      estimatedMonthlyPayment,
      jobTenureMonths: parseFloat(formData.jobTenure) || 0,
      employmentStatus: formData.employmentStatus
    });
    
    setVerdict(result);
    setShowVerdict(true);
    setIsLoading(false);
  };
  
  // Handle confirmation to proceed
  const handleProceed = () => {
    if (verdict?.status === 'likely_eligible') {
      onApplyLoan();
    } else {
      onSkipToFullApplication();
    }
    onClose();
  };
  
  // Handle modal backdrop click
  const handleBackdropClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };
  
  // Handle keyboard navigation
  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      onClose();
    } else if (e.key === 'Enter' && !showVerdict && !isLoading) {
      handleEstimate();
    }
  };
  
  if (!isOpen) return null;
  
  return (
    <div 
      className="modal-backdrop" 
      onClick={handleBackdropClick}
      onKeyDown={handleKeyDown}
      tabIndex={-1}
      aria-modal="true"
      role="dialog"
    >
      <div className="modal-container" ref={modalRef}>
        
        {/* Header */}
        <div className="modal-header">
          <h2>{STRINGS.title}</h2>
          <button 
            onClick={onClose}
            className="close-button"
            aria-label="Close modal"
          >
            ×
          </button>
        </div>
        
        {/* Subtitle */}
        <p className="modal-subtitle">
          {STRINGS.subtitle}
        </p>
        
        {/* Form */}
        {!showVerdict && (
          <div className="modal-form">
            <p className="form-help-text">
              {STRINGS.incomeHelp}
            </p>
            
            {/* Employment Status */}
            <div className="form-group">
              <label htmlFor="employment-status">
                {STRINGS.employmentStatus} *
              </label>
              <select
                id="employment-status"
                value={formData.employmentStatus}
                onChange={(e) => handleInputChange('employmentStatus', e.target.value)}
                required
                aria-describedby="employment-help"
              >
                <option value="">Select employment status</option>
                {STRINGS.employmentOptions.map(option => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            
            {/* Monthly Income */}
            <div className="form-group">
              <label htmlFor="monthly-income">
                {STRINGS.monthlyIncome} *
              </label>
              <div className="currency-input">
                <span className="currency-symbol">₱</span>
                <input
                  id="monthly-income"
                  type="text"
                  inputMode="numeric"
                  value={formData.monthlyIncome}
                  onChange={(e) => handleCurrencyInput('monthlyIncome', e.target.value)}
                  placeholder="50,000"
                  required
                />
              </div>
            </div>
            
            {/* Monthly Obligations */}
            <div className="form-group">
              <label htmlFor="monthly-obligations">
                {STRINGS.monthlyObligations} *
              </label>
              <div className="currency-input">
                <span className="currency-symbol">₱</span>
                <input
                  id="monthly-obligations"
                  type="text"
                  inputMode="numeric"
                  value={formData.monthlyObligations}
                  onChange={(e) => handleCurrencyInput('monthlyObligations', e.target.value)}
                  placeholder="20,000"
                  required
                />
              </div>
            </div>
            
            {/* Job Tenure */}
            <div className="form-group">
              <label htmlFor="job-tenure">
                {STRINGS.jobTenure}
              </label>
              <input
                id="job-tenure"
                type="number"
                min="0"
                max="120"
                value={formData.jobTenure}
                onChange={(e) => handleInputChange('jobTenure', e.target.value.replace(/[^\d]/g, ''))}
                placeholder="6"
              />
              <small className="help-text">
                How many months in your current job (optional)
              </small>
            </div>
            
            {/* Upload Payslip */}
            <div className="form-group">
              <label htmlFor="payslip-upload">
                {STRINGS.uploadPayslip}
              </label>
              <input
                id="payslip-upload"
                type="file"
                accept="image/*"
                multiple
                onChange={handlePayslipUpload}
                className="file-input"
              />
              <small className="help-text">
                Optional proof of income
              </small>
            </div>
            
            {/* Privacy Note */}
            <p className="privacy-note">
              {STRINGS.privacyNote}
            </p>
          </div>
        )}
        
        {/* Verdict Display */}
        {showVerdict && verdict && (
          <div className={`verdict-container verdict-${verdict.status}`}>
            <div className="verdict-header">
              <h3>{verdict.status === 'likely_eligible' ? '✅ Likely Eligible' : 
                   verdict.status === 'needs_review' ? '⚠️ Needs Review' : 
                   '❌ Not Recommended'}</h3>
            </div>
            
            <div className="verdict-metrics">
              <div className="metric">
                <span className="metric-label">DTI:</span>
                <span className="metric-value">{(verdict.dti * 100).toFixed(1)}%</span>
              </div>
              <div className="metric">
                <span className="metric-label">Allowed monthly:</span>
                <span className="metric-value">₱{formatCurrency(verdict.allowedMonthly)}</span>
              </div>
              <div className="metric">
                <span className="metric-label">Proposed payment:</span>
                <span className="metric-value">₱{formatCurrency(verdict.estimatedMonthlyPayment)}</span>
              </div>
            </div>
            
            <div className="verdict-reason">
              <p>
                {verdict.status === 'likely_eligible' ? 
                  STRINGS.likelyEligible(currentLoanAmount, verdict.estimatedMonthlyPayment) :
                  verdict.status === 'needs_review' ?
                  STRINGS.needsReview(verdict.reason) :
                  STRINGS.notRecommended(verdict.dti)
                }
              </p>
            </div>
          </div>
        )}
        
        {/* Action Buttons */}
        <div className="modal-actions">
          {!showVerdict ? (
            <>
              <button
                onClick={handleEstimate}
                disabled={isLoading || !formData.monthlyIncome || !formData.monthlyObligations}
                className="btn btn-primary"
              >
                {isLoading ? 'Calculating...' : STRINGS.estimateNow}
              </button>
              <button
                onClick={() => {
                  onSkipToFullApplication();
                  onClose();
                }}
                className="btn btn-secondary"
              >
                {STRINGS.skipContinue}
              </button>
            </>
          ) : (
            <>
              {verdict.status === 'needs_review' && (
                <button
                  onClick={handleProceed}
                  className="btn btn-warning"
                >
                  {STRINGS.confirmContinue}
                </button>
              )}
              {verdict.status === 'likely_eligible' && (
                <button
                  onClick={handleProceed}
                  className="btn btn-success"
                >
                  Apply Loan Now
                </button>
              )}
              <button
                onClick={() => {
                  setShowVerdict(false);
                  setVerdict(null);
                }}
                className="btn btn-secondary"
              >
                Back to Edit
              </button>
              <button
                onClick={() => {
                  onSkipToFullApplication();
                  onClose();
                }}
                className="btn btn-tertiary"
              >
                Skip to Full Application
              </button>
            </>
          )}
        </div>
      
      </div>
      
      {/* Modal Styles */}
      <style jsx>{`
        .modal-backdrop {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.5);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
          padding: 16px;
        }
        
        .modal-container {
          background: white;
          border-radius: 12px;
          width: 100%;
          max-width: 480px;
          max-height: 90vh;
          overflow-y: auto;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
        }
        
        .modal-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 20px 24px 16px;
          border-bottom: 1px solid #e0e0e0;
        }
        
        .modal-header h2 {
          margin: 0;
          font-size: 18px;
          font-weight: 600;
          color: #1a1a1a;
        }
        
        .close-button {
          background: none;
          border: none;
          font-size: 24px;
          cursor: pointer;
          color: #666;
          padding: 0;
          width: 32px;
          height: 32px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .modal-subtitle {
          padding: 16px 24px;
          margin: 0;
          font-size: 14px;
          color: #666;
          border-bottom: 1px solid #f0f0f0;
        }
        
        .modal-form {
          padding: 24px;
        }
        
        .form-help-text {
          margin: 0 0 20px;
          font-size: 14px;
          color: #444;
          line-height: 1.5;
        }
        
        .form-group {
          margin-bottom: 20px;
        }
        
        .form-group label {
          display: block;
          margin-bottom: 6px;
          font-weight: 500;
          color: #333;
          font-size: 14px;
        }
        
        .form-group input,
        .form-group select {
          width: 100%;
          padding: 12px;
          border: 2px solid #ddd;
          border-radius: 8px;
          font-size: 16px;
          transition: border-color 0.2s;
          box-sizing: border-box;
        }
        
        .form-group input:focus,
        .form-group select:focus {
          outline: none;
          border-color: #007bff;
          box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
        }
        
        .currency-input {
          position: relative;
          display: flex;
          align-items: center;
        }
        
        .currency-symbol {
          position: absolute;
          left: 12px;
          color: #666;
          font-weight: 500;
          pointer-events: none;
          z-index: 1;
        }
        
        .currency-input input {
          padding-left: 32px;
        }
        
        .file-input {
          padding: 8px !important;
          cursor: pointer;
        }
        
        .help-text {
          display: block;
          margin-top: 4px;
          font-size: 12px;
          color: #666;
        }
        
        .privacy-note {
          background: #f8f9fa;
          padding: 12px;
          border-radius: 6px;
          font-size: 12px;
          color: #666;
          margin: 16px 0 0;
          line-height: 1.4;
        }
        
        .verdict-container {
          padding: 24px;
          border-radius: 8px;
          margin: 20px 0;
        }
        
        .verdict-likely_eligible {
          background: #e8f5e8;
          border: 1px solid #4caf50;
        }
        
        .verdict-needs_review {
          background: #fff3cd;
          border: 1px solid #ff9800;
        }
        
        .verdict-not_recommended {
          background: #f8d7da;
          border: 1px solid #f44336;
        }
        
        .verdict-header h3 {
          margin: 0 0 16px;
          font-size: 16px;
        }
        
        .verdict-metrics {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 12px;
          margin-bottom: 16px;
        }
        
        .metric {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 8px 12px;
          background: rgba(255, 255, 255, 0.7);
          border-radius: 6px;
        }
        
        .metric-label {
          font-size: 13px;
          color: #555;
        }
        
        .metric-value {
          font-weight: 600;
          font-size: 13px;
        }
        
        .verdict-reason p {
          margin: 0;
          font-size: 14px;
          line-height: 1.4;
        }
        
        .modal-actions {
          padding: 24px;
          border-top: 1px solid #e0e0e0;
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
        }
        
        .btn {
          padding: 12px 20px;
          border-radius: 8px;
          border: none;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
          flex: 1;
          min-width: 120px;
        }
        
        .btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        
        .btn-primary {
          background: #007bff;
          color: white;
        }
        
        .btn-primary:hover:not(:disabled) {
          background: #0056b3;
        }
        
        .btn-secondary {
          background: #f8f9fa;
          color: #333;
          border: 1px solid #ddd;
        }
        
        .btn-secondary:hover {
          background: #e9ecef;
        }
        
        .btn-success {
          background: #28a745;
          color: white;
        }
        
        .btn-success:hover {
          background: #1e7e34;
        }
        
        .btn-warning {
          background: #ffc107;
          color: #333;
        }
        
        .btn-warning:hover {
          background: #e0a800;
        }
        
        .btn-tertiary {
          background: transparent;
          color: #666;
          border: 1px solid #ddd;
        }
        
        .btn-tertiary:hover {
          background: #f8f9fa;
        }
        
        @media (max-width: 480px) {
          .modal-actions {
            flex-direction: column;
          }
          
          .btn {
            flex: none;
            width: 100%;
          }
          
          .verdict-metrics {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </div>
  );
};

export default AffordabilityModal;
