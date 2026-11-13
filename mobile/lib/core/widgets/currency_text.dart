import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CurrencyText extends StatelessWidget {
  final int amountInPaise;
  final String currencySymbol;
  final TextStyle? style;
  final bool showSign;
  final bool isExpense;
  final bool isIncome;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? customColor;

  const CurrencyText({
    super.key,
    int? amountInPaise,
    int? amountPaise,
    this.currencySymbol = '₹',
    this.style,
    this.showSign = false,
    this.isExpense = false,
    this.isIncome = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.customColor,
  }) : amountInPaise = amountInPaise ?? amountPaise ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    Color color = customColor ?? defaultColor;
    String sign = '';

    if (isIncome) {
      color = AppColors.income;
      if (showSign) sign = '+';
    } else if (isExpense) {
      color = AppColors.expense;
      if (showSign) sign = '-';
    } else if (amountInPaise < 0) {
      color = AppColors.expense;
      sign = '-';
    }

    final double amountInRupees = (amountInPaise.abs()) / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: amountInRupees % 1 == 0 ? 0 : 2,
    );

    final formatted = formatter.format(amountInRupees);

    return Text(
      '$sign$formatted',
      style: style ??
          AppTypography.titleMedium(color).copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
    );
  }
}
