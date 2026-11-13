import 'package:flutter/services.dart';

/// Provides audio and haptic feedback for financial actions.
/// Simulates Google Pay style positive chime/vibration on income
/// and distinct alert/feedback on expenditure or deletion.
class AppSoundService {
  /// Upbeat dual-tone haptic & audio feedback for receiving money (Google Pay style)
  static void playIncomeChime() {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      Future.delayed(const Duration(milliseconds: 140), () {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      });
    } catch (_) {}
  }

  /// Distinct alert pulse for money spent / expense recorded
  static void playExpenseAlert() {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Warning vibration and alert for deletion actions
  static void playDeleteWarning() {
    try {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Pleasant confirmation for successful updates / saves
  static void playSuccess() {
    try {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
