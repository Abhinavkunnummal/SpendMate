import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/app_sound_service.dart';

/// Standard confirmation dialog for deleting transactions, wallets, trips, or EMIs.
/// Shows clear warning text, provides Cancel / Delete actions, and plays warning haptic.
class DeleteConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
  }) async {
    AppSoundService.playDeleteWarning();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                AppSoundService.playExpenseAlert();
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
