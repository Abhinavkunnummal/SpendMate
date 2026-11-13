import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';

class TripItineraryScreen extends StatefulWidget {
  final String tripId;
  const TripItineraryScreen({super.key, required this.tripId});

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  int _selectedDay = 0;

  final List<Map<String, dynamic>> _days = [
    {
      'day': 'Day 1',
      'date': '18 Nov',
      'title': 'Departure & Transit to Himachal',
      'activities': [
        {'time': '07:30 PM', 'title': 'Volvo Bus Boarding', 'location': 'Majnu Ka Tilla, Delhi', 'cost': '₹3,200', 'done': true},
        {'time': '10:00 PM', 'title': 'Dinner Halt at Highway Dhaba', 'location': 'Murthal', 'cost': '₹850', 'done': true},
      ],
    },
    {
      'day': 'Day 2',
      'date': '19 Nov',
      'title': 'Old Manali Arrival & Riverside Leisure',
      'activities': [
        {'time': '09:00 AM', 'title': 'Check-in to Riverside Pine Cottage', 'location': 'Old Manali', 'cost': '₹12,000', 'done': false},
        {'time': '01:00 PM', 'title': 'Lunch & Craft Cider Tasting', 'location': 'Café 1947', 'cost': '₹2,400', 'done': false},
        {'time': '04:30 PM', 'title': 'Walk through Cedar Forest to Hadimba Temple', 'location': 'Hadimba Road', 'cost': '₹200', 'done': false},
      ],
    },
    {
      'day': 'Day 3',
      'date': '20 Nov',
      'title': 'Solang Valley & Snow Adventures',
      'activities': [
        {'time': '08:30 AM', 'title': 'Drive through Atal Tunnel', 'location': 'Atal Tunnel South Portal', 'cost': '₹4,500', 'done': false},
        {'time': '11:00 AM', 'title': 'Skiing & Snow Tubing in Sissu', 'location': 'Sissu Valley', 'cost': '₹6,000', 'done': false},
        {'time': '06:00 PM', 'title': 'Bonfire & Barbecue at Cottage', 'location': 'Cottage Garden', 'cost': '₹1,800', 'done': false},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final currentDay = _days[_selectedDay];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Itinerary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Tabs Horizontal List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(_days.length, (index) {
                final d = _days[index];
                final isSelected = _selectedDay == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index < _days.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d['day'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : primaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d['date'],
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // Day Plan Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDay['title'],
                    style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 16),

                  // Activities Timeline
                  ...(currentDay['activities'] as List<Map<String, dynamic>>).map((act) {
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.blueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              act['time'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act['title'],
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(act['location'], style: AppTypography.bodySmall(secondaryTextColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            act['cost'],
                            style: AppTypography.labelLarge(primaryTextColor).copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  AppButton(
                    text: '+ Add Activity to ${currentDay['day']}',
                    variant: ButtonVariant.outline,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
