import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/data/app_data_repository.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  bool _isScanned = false;
  bool _isProcessing = false;
  int _selectedTemplateIndex = 0;

  final List<Map<String, dynamic>> _receiptTemplates = [
    {
      'merchant': 'Starbucks Coffee Reserve',
      'category': 'Food & Dining',
      'amountPaise': 52500, // ₹525.00
      'date': 'Today, 09:40 AM',
      'items': [
        {'name': 'Caramel Macchiato Grande', 'price': '₹345.00'},
        {'name': 'Butter Croissant', 'price': '₹180.00'},
        {'name': 'CGST/SGST (5%)', 'price': '₹25.00'},
      ],
    },
    {
      'merchant': 'Reliance Fresh Supermarket',
      'category': 'Groceries',
      'amountPaise': 184000, // ₹1,840.00
      'date': 'Yesterday, 06:15 PM',
      'items': [
        {'name': 'Organic Almond Milk 1L', 'price': '₹280.00'},
        {'name': 'Farm Fresh Eggs (Pack of 12)', 'price': '₹160.00'},
        {'name': 'Whole Grain Sourdough Loaf', 'price': '₹140.00'},
        {'name': 'Imported Olive Oil 500ml', 'price': '₹1,260.00'},
      ],
    },
    {
      'merchant': 'HP Auto Care Fuel Station',
      'category': 'Transport & Fuel',
      'amountPaise': 250000, // ₹2,500.00
      'date': '12 Nov 2026, 11:20 AM',
      'items': [
        {'name': 'Power 95 Petrol (24.2 Litres)', 'price': '₹2,500.00'},
      ],
    },
    {
      'merchant': 'PVR Cinemas IMAX',
      'category': 'Movies & Cinema',
      'amountPaise': 98000, // ₹980.00
      'date': '11 Nov 2026, 07:15 PM',
      'items': [
        {'name': '2x IMAX Recliner Tickets', 'price': '₹760.00'},
        {'name': 'Cheese Popcorn Tub', 'price': '₹220.00'},
      ],
    },
  ];

  void _triggerScan() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isScanned = true;
      });
      AppSoundService.playSuccess();
    });
  }

  void _saveExpense() async {
    final current = _receiptTemplates[_selectedTemplateIndex];
    final repoWallets = AppDataRepository.instance.wallets;
    final walletName = repoWallets.isNotEmpty ? repoWallets.first.name : 'Primary Bank Account';

    await AppDataRepository.instance.addTransaction(
      title: current['merchant'],
      amountPaise: current['amountPaise'],
      isExpense: true,
      category: current['category'],
      wallet: walletName,
      date: DateTime.now(),
    );

    AppSoundService.playExpenseAlert();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${current['merchant']}" (₹${(current['amountPaise'] / 100).toStringAsFixed(0)}) to expenses!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final currentReceipt = _receiptTemplates[_selectedTemplateIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Receipt Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
            onPressed: () => setState(() => _isScanned = false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Camera / Viewfinder Box
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 180,
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
                        SizedBox(height: 14),
                        Text(
                          'Extracting OCR Data with AI...',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ] else if (!_isScanned) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.document_scanner_rounded, size: 44, color: Colors.white70),
                        const SizedBox(height: 10),
                        const Text(
                          'Point camera at bill or upload photo',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: List.generate(_receiptTemplates.length, (idx) {
                            final isSel = _selectedTemplateIndex == idx;
                            return ChoiceChip(
                              label: Text(
                                idx == 0 ? '☕ Coffee' : (idx == 1 ? '🛒 Grocery' : (idx == 2 ? '⛽ Fuel' : '🎬 Movie')),
                                style: TextStyle(
                                  color: isSel ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white24,
                              onSelected: (_) => setState(() => _selectedTemplateIndex = idx),
                            );
                          }),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          '${currentReceipt['merchant']} Detected!',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scan Action Buttons
            if (!_isScanned) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _triggerScan,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Pick Photo'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _triggerScan,
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
                        Text('PARSED RECEIPT DETAILS', style: AppTypography.labelSmall(AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '98% AI Match',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentReceipt['merchant'],
                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(currentReceipt['amountPaise'] / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.coral),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Items breakdown
                    ...(currentReceipt['items'] as List<Map<String, String>>).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name']!, style: TextStyle(fontSize: 13, color: primaryTextColor)),
                            Text(item['price']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Instant Add Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveExpense,
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Save Directly to Expenses',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isScanned = false),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Scan Another Receipt'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
