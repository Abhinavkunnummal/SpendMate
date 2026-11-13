import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/app_sound_service.dart';

/// Interactive Apple-inspired in-app quick calculator sheet.
/// Allows swift arithmetic calculations (e.g. splitting bills or adding multiple items)
/// before entering transaction or budget amounts.
class QuickCalculatorSheet extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onAmountSelected;

  const QuickCalculatorSheet({
    super.key,
    this.initialValue = 0,
    required this.onAmountSelected,
  });

  static Future<double?> show(BuildContext context, {double initialValue = 0}) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickCalculatorSheet(
        initialValue: initialValue,
        onAmountSelected: (val) => Navigator.pop(ctx, val),
      ),
    );
  }

  @override
  State<QuickCalculatorSheet> createState() => _QuickCalculatorSheetState();
}

class _QuickCalculatorSheetState extends State<QuickCalculatorSheet> {
  String _expression = '';
  double _currentResult = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      _expression = widget.initialValue % 1 == 0
          ? widget.initialValue.toInt().toString()
          : widget.initialValue.toString();
      _currentResult = widget.initialValue;
    }
  }

  void _onKeyPress(String key) {
    AppSoundService.playSuccess();
    setState(() {
      if (key == 'C') {
        _expression = '';
        _currentResult = 0;
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _evaluate();
        }
      } else if (['+', '-', '×', '÷'].contains(key)) {
        if (_expression.isNotEmpty && !['+', '-', '×', '÷'].contains(_expression[_expression.length - 1])) {
          _expression += key;
        }
      } else {
        _expression += key;
        _evaluate();
      }
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _currentResult = 0;
      return;
    }
    try {
      // Simple parser for standard + - * / arithmetic
      final sanitized = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      final tokens = RegExp(r'(\d+\.?\d*|[+\-*/])').allMatches(sanitized).map((m) => m.group(0)!).toList();

      if (tokens.isEmpty) return;

      // First pass: multiplication & division
      final List<String> intermediate = [];
      int i = 0;
      while (i < tokens.length) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          if (intermediate.isNotEmpty && i + 1 < tokens.length) {
            final prev = double.tryParse(intermediate.removeLast()) ?? 0;
            final next = double.tryParse(tokens[i + 1]) ?? 1;
            final res = tokens[i] == '*' ? prev * next : (next != 0 ? prev / next : prev);
            intermediate.add(res.toString());
            i += 2;
            continue;
          }
        }
        intermediate.add(tokens[i]);
        i++;
      }

      // Second pass: addition & subtraction
      double total = double.tryParse(intermediate.isNotEmpty ? intermediate[0] : '0') ?? 0;
      int j = 1;
      while (j < intermediate.length) {
        final op = intermediate[j];
        if (j + 1 < intermediate.length) {
          final next = double.tryParse(intermediate[j + 1]) ?? 0;
          if (op == '+') total += next;
          if (op == '-') total -= next;
          j += 2;
        } else {
          break;
        }
      }

      if (total >= 0) {
        _currentResult = total;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 28, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fast Calculator', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 17)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expression.isEmpty ? '0' : _expression,
                  style: TextStyle(
                    fontSize: 18,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_currentResult.toStringAsFixed(_currentResult % 1 == 0 ? 0 : 2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Calculator Keypad Grid
          _keypad(isDark, primaryTextColor),
          const SizedBox(height: 16),

          // Use Amount Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                AppSoundService.playIncomeChime();
                widget.onAmountSelected(_currentResult);
              },
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              label: Text(
                'Use ₹${_currentResult.toStringAsFixed(_currentResult % 1 == 0 ? 0 : 2)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad(bool isDark, Color textColor) {
    final rows = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '.'],
      ['0', '00'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: row.map((key) {
              final isOperator = ['+', '-', '×', '÷'].contains(key);
              final isClear = key == 'C' || key == '⌫';
              final flex = key == '0' ? 2 : 1;

              return Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => _onKeyPress(key),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isOperator
                            ? AppColors.primary.withOpacity(0.15)
                            : (isClear
                                ? AppColors.coral.withOpacity(0.12)
                                : (isDark ? AppColors.surfaceDark : Colors.grey.shade100)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: isOperator || isClear ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: isOperator
                              ? AppColors.primary
                              : (isClear ? AppColors.coral : textColor),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
