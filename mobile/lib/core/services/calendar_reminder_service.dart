import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to generate Google Calendar reminders for EMIs and credit card due dates.
class CalendarReminderService {
  /// Generates a universal Google Calendar web intent URL
  static String generateGoogleCalendarUrl({
    required String title,
    required String description,
    required DateTime dueDate,
  }) {
    final startStr = dueDate.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';
    final endStr = dueDate.add(const Duration(hours: 1)).toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'details': description,
      'dates': '$startStr/$endStr',
      'recur': 'RRULE:FREQ=MONTHLY',
    });

    return uri.toString();
  }

  /// Copies Google Calendar reminder link and shows instructions
  static void openOrCopyGoogleCalendarReminder(
    BuildContext context, {
    required String title,
    required String description,
    required DateTime dueDate,
  }) {
    final url = generateGoogleCalendarUrl(
      title: title,
      description: description,
      dueDate: dueDate,
    );

    Clipboard.setData(ClipboardData(text: url));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.calendar_month_rounded, color: Color(0xFF4285F4)),
            SizedBox(width: 10),
            Expanded(
              child: Text('Google Calendar Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: $title', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Scheduled Due Date: ${dueDate.day}/${dueDate.month}/${dueDate.year}'),
            const SizedBox(height: 12),
            const Text(
              'The direct Google Calendar monthly recurring event link has been copied to your clipboard. Paste and open it in your browser or calendar app to sync reminders.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar reminder link copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
