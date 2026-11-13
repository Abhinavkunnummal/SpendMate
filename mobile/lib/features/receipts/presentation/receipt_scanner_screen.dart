import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/currency_text.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  bool _isScanned = false;
  bool _isProcessing = false;

  void _simulateScan() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isScanned = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Receipt Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Viewfinder Camera Mock
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Corner Guides
                  Container(
                    width: 220,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (_isProcessing) ...[
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text(
                          'Extracting OCR Data with AI...',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ] else if (!_isScanned) ...[
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 48, color: Colors.white70),
                        SizedBox(height: 10),
                        Text(
                          'Align physical receipt inside the frame',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scan / Capture Buttons
            if (!_isScanned) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _simulateScan,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Upload Photo'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _simulateScan,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Capture & Parse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Parsed OCR Details Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PARSED RECEIPT', style: AppTypography.labelSmall(AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '96% AI Accuracy',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Blue Tokai Coffee Roasters',
                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const CurrencyText(amountPaise: 48000, fontSize: 24, fontWeight: FontWeight.w700),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    _lineItem('Flat White (Oat Milk)', '₹280.00', primaryTextColor, secondaryTextColor),
                    const SizedBox(height: 6),
                    _lineItem('Almond Croissant', '₹200.00', primaryTextColor, secondaryTextColor),
                    const SizedBox(height: 6),
                    _lineItem('CGST / SGST (5%)', '₹24.00', secondaryTextColor, secondaryTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              AppButton(
                text: 'Save as Personal Expense',
                onPressed: () => context.push('/add-transaction'),
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Add to Manali Group Trip',
                variant: ButtonVariant.outline,
                onPressed: () => context.push('/trips/trip-manali-101/add-expense'),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _lineItem(String label, String amount, Color labelColor, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor)),
      ],
    );
  }
}
