// =============================================================================
// FLUTTER AFFORDABILITY MODAL WIDGET
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'affordability_calculator.dart';

// =============================================================================
// AFFORDABILITY MODAL COMPONENT
// =============================================================================

class AffordabilityModal extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onApplyLoan;
  final VoidCallback onSkipToFullApplication;
  final double currentLoanAmount;
  final int currentLoanTerm;

  const AffordabilityModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onApplyLoan,
    required this.onSkipToFullApplication,
    this.currentLoanAmount = 0,
    this.currentLoanTerm = 12,
  });

  @override
  State<AffordabilityModal> createState() => _AffordabilityModalState();
}

class _AffordabilityModalState extends State<AffordabilityModal> {
  // Form controllers
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _obligationsController = TextEditingController();
  final TextEditingController _jobTenureController = TextEditingController();

  // Form state
  String? _selectedEmploymentStatus;

  // UI state
  bool _showVerdict = false;
  AffordabilityVerdict? _verdict;
  bool _isLoading = false;

  @override
  void dispose() {
    _incomeController.dispose();
    _obligationsController.dispose();
    _jobTenureController.dispose();
    super.dispose();
  }

  void _handleCurrencyInput(String value, TextEditingController controller) {
    final formattedValue = AffordabilityStrings.formatCurrencyInput(value);

    if (formattedValue != controller.text) {
      controller.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  Future<void> _estimateAffordability() async {
    final incomeText = _incomeController.text.replaceAll(',', '');
    final obligationsText = _obligationsController.text.replaceAll(',', '');
    final income = double.tryParse(incomeText) ?? 0;
    final obligations = double.tryParse(obligationsText) ?? 0;

    if (income <= 0 || obligations < 0) {
      _showSnackBar('Please enter valid monthly income and obligations');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate calculation delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Calculate estimated monthly payment
    final estimatedPayment =
        widget.currentLoanAmount > 0 && widget.currentLoanTerm > 0
        ? widget.currentLoanAmount / widget.currentLoanTerm.toDouble()
        : 0.0;

    // Calculate job tenure
    final jobTenure = int.tryParse(_jobTenureController.text) ?? 0;

    // Get verdict
    final verdict = AffordabilityCalculator.decideVerdict(
      monthlyIncome: income,
      monthlyObligations: obligations,
      estimatedMonthlyPayment: estimatedPayment,
      jobTenureMonths: jobTenure,
      employmentStatus: _selectedEmploymentStatus ?? 'employed',
    );

    setState(() {
      _verdict = verdict;
      _showVerdict = true;
      _isLoading = false;
    });
  }

  void _proceedWithApplication() {
    if (_verdict?.status == AffordabilityStatus.likelyEligible) {
      widget.onApplyLoan();
    } else {
      widget.onSkipToFullApplication();
    }
    widget.onClose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AffordabilityStrings.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 24,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  AffordabilityStrings.subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),

              // Form or Verdict Display
              if (!_showVerdict)
                _buildForm()
              else if (_verdict != null)
                _buildVerdict(),
            ],
          ),
        ),
      ),
      actions: _buildActions(),
      actionsPadding: const EdgeInsets.all(20),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Help text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            AffordabilityStrings.incomeHelp,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),

        const SizedBox(height: 20),

        // Employment Status
        _buildEmploymentDropdown(),

        const SizedBox(height: 16),

        // Monthly Income
        _buildCurrencyInput(
          label: '${AffordabilityStrings.monthlyIncome} *',
          controller: _incomeController,
          hintText: '50,000',
        ),

        const SizedBox(height: 16),

        // Monthly Obligations
        _buildCurrencyInput(
          label: '${AffordabilityStrings.monthlyObligations} *',
          controller: _obligationsController,
          hintText: '20,000',
        ),

        const SizedBox(height: 16),

        // Job Tenure
        _buildNumericInput(
          label: AffordabilityStrings.jobTenure,
          controller: _jobTenureController,
          hintText: '6',
          helpText: 'How many months in your current job (optional)',
        ),

        const SizedBox(height: 16),

        // Privacy Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AffordabilityStrings.privacyNote,
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AffordabilityStrings.employmentStatus} *',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedEmploymentStatus,
          decoration: const InputDecoration(
            hintText: 'Select employment status',
            border: OutlineInputBorder(),
          ),
          items: AffordabilityStrings.employmentOptions.entries.map((entry) {
            return DropdownMenuItem(value: entry.key, child: Text(entry.value));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmploymentStatus = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select employment status';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixText: '₱ ',
            prefixStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          onChanged: (value) => _handleCurrencyInput(value, controller),
        ),
      ],
    );
  }

  Widget _buildNumericInput({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildVerdict() {
    if (_verdict == null) return const SizedBox.shrink();

    Color backgroundColor;
    Color borderColor;

    switch (_verdict!.status) {
      case AffordabilityStatus.likelyEligible:
        backgroundColor = Colors.green[50]!;
        borderColor = Colors.green[300]!;
        break;
      case AffordabilityStatus.needsReview:
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange[300]!;
        break;
      case AffordabilityStatus.notRecommended:
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[300]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Status Header
          Text(
            _verdict!.statusDisplay,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          // Metrics Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3,
            children: [
              _buildMetricItem(
                'DTI:',
                '${(_verdict!.dti * 100).toStringAsFixed(1)}%',
              ),
              _buildMetricItem(
                'Allowed monthly:',
                '₱${AffordabilityStrings.formatCurrency(_verdict!.allowedMonthly)}',
              ),
              _buildMetricItem(
                'Proposed payment:',
                '₱${AffordabilityStrings.formatCurrency(_verdict!.estimatedMonthlyPayment)}',
              ),
              _buildMetricItem(
                'Employment:',
                AffordabilityStrings.employmentOptions[_verdict!
                        .employmentStatus] ??
                    _verdict!.employmentStatus,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reason Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _verdict!.statusMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (!_showVerdict) {
      return [
        // Just Estimate button - no skip option
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _isLoading ||
                    _incomeController.text.isEmpty ||
                    _obligationsController.text.isEmpty
                ? null
                : _estimateAffordability,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AffordabilityStrings.estimateNow),
          ),
        ),
      ];
    } else {
      // Verdict-based actions
      switch (_verdict!.status) {
        case AffordabilityStatus.likelyEligible:
          return [
            TextButton(
              onPressed: () {
                setState(() {
                  _showVerdict = false;
                  _verdict = null;
                });
              },
              child: const Text('Back to Edit'),
            ),
            ElevatedButton(
              onPressed: _proceedWithApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Loan Now'),
            ),
          ];

        case AffordabilityStatus.needsReview:
          return [
            TextButton(
              onPressed: () {
                setState(() {
                  _showVerdict = false;
                  _verdict = null;
                });
              },
              child: const Text('Back to Edit'),
            ),
            ElevatedButton(
              onPressed: _proceedWithApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AffordabilityStrings.confirmContinue),
            ),
          ];

        case AffordabilityStatus.notRecommended:
          return [
            TextButton(
              onPressed: () {
                setState(() {
                  _showVerdict = false;
                  _verdict = null;
                });
              },
              child: const Text('Back to Edit'),
            ),
            // NO skip button for not recommended - forces user to reconsider
          ];
      }
    }
  }
}