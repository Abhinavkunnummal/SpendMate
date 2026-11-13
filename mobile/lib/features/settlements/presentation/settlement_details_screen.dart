import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class SettlementDetailsScreen extends StatefulWidget {
  final String settlementId;
  final String fromName;
  final String toName;
  final int amountPaise;
  final String tripId;

  const SettlementDetailsScreen({
    super.key,
    required this.settlementId,
    this.fromName = 'Payer',
    this.toName = 'Receiver',
    this.amountPaise = 0,
    this.tripId = '',
  });

  @override
  State<SettlementDetailsScreen> createState() => _SettlementDetailsScreenState();
}

class _SettlementDetailsScreenState extends State<SettlementDetailsScreen> {
  bool _isSettled = false;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _receiverUpiId {
    final clean = widget.toName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
    return clean.isEmpty ? 'spendmate@upi' : '$clean@upi';
  }

  void _copyUpi() {
    Clipboard.setData(ClipboardData(text: _receiverUpiId));
    AppSoundService.playChime();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('UPI ID "$_receiverUpiId" copied to clipboard!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _shareSlip() {
    AppSoundService.playSuccess();
    final amountFormatted = (widget.amountPaise / 100).toStringAsFixed(2);
    final slip = StringBuffer()
      ..writeln('====================================')
      ..writeln('   SPENDMATE TRIP SETTLEMENT SLIP   ')
      ..writeln('====================================')
      ..writeln('From: ${widget.fromName}')
      ..writeln('To:   ${widget.toName}')
      ..writeln('Amount: ₹$amountFormatted')
      ..writeln('Status: ${_isSettled ? "Settled & Verified ✅" : "Pending ⏳"}')
      ..writeln('Receiver UPI: $_receiverUpiId')
      ..writeln('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}')
      ..writeln('------------------------------------')
      ..writeln('Settled with SpendMate')
      ..writeln('====================================');

    Clipboard.setData(ClipboardData(text: slip.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settlement slip copied! Paste in WhatsApp to share with members.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final myName = AuthSessionManager.instance.displayName;
    final isReceiverMe = widget.toName.toLowerCase().contains(myName.toLowerCase()) ||
        widget.toName.toLowerCase().contains('you');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Settlement Slip',
            onPressed: _shareSlip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Payer to Receiver Avatar Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.coralLight,
                  child: Text(
                    _initials(widget.fromName),
                    style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    _initials(widget.toName),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              '${widget.fromName} pays ${widget.toName}',
              style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CurrencyText(
              amountPaise: widget.amountPaise,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 10),
            StatusBadge(
              label: _isSettled ? 'Settled & Verified' : 'Pending Payment',
              color: _isSettled ? AppColors.primary : AppColors.orange,
              icon: _isSettled ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            ),
            const SizedBox(height: 28),

            // UPI QR & Payment Info Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.primary.withOpacity(0.9)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('${widget.toName} UPI ID', style: AppTypography.bodySmall(secondaryTextColor)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _copyUpi,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _receiverUpiId,
                            style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AppButton(
              text: 'Copy Payment Link & UPI ID',
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              onPressed: _copyUpi,
            ),
            const SizedBox(height: 12),

            AppButton(
              text: _isSettled
                  ? 'Payment Completed ✅'
                  : (isReceiverMe ? 'Mark as Received & Settled' : 'Mark as Paid & Settled'),
              variant: ButtonVariant.outline,
              onPressed: () {
                AppSoundService.playSuccess();
                setState(() => _isSettled = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settlement between ${widget.fromName} and ${widget.toName} marked as completed!',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
