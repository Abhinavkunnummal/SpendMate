import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendmate/core/data/app_data_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Trip Settlements & Debt Minimization Tests', () {
    test('TripModelItem correctly serializes and deserializes settlements', () {
      final trip = TripModelItem(
        id: 'trip_test_1',
        name: 'Goa Trip',
        destination: 'Goa',
        budgetPaise: 1500000,
        spentPaise: 600000,
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 5),
        members: ['Abhi', 'Rahul', 'Kiran'],
        expenses: [
          {
            'id': 'exp_1',
            'title': 'Resort Stay',
            'amountPaise': 600000,
            'paidBy': 'Abhi',
          }
        ],
        settlements: [
          {
            'id': 'settle_1',
            'from': 'Rahul',
            'to': 'Abhi',
            'amountPaise': 200000,
            'settledAt': '2026-11-14T00:00:00.000',
            'method': 'UPI Direct',
          }
        ],
      );

      final json = trip.toJson();
      expect(json['settlements'], isNotEmpty);
      expect((json['settlements'] as List).length, equals(1));

      final fromJsonTrip = TripModelItem.fromJson(json);
      expect(fromJsonTrip.settlements.length, equals(1));
      expect(fromJsonTrip.settlements[0]['from'], equals('Rahul'));
      expect(fromJsonTrip.settlements[0]['to'], equals('Abhi'));
      expect(fromJsonTrip.settlements[0]['amountPaise'], equals(200000));
    });

    test('AppDataRepository records and deletes trip settlements seamlessly', () async {
      final repo = AppDataRepository.instance;
      await repo.initialize();

      await repo.addTrip(
        name: 'Munnar Trek',
        destination: 'Munnar',
        budgetPaise: 1000000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        members: ['Abhi', 'Rahul'],
      );

      final tripId = repo.trips.first.id;

      // Record a settlement
      await repo.recordTripSettlement(
        tripId: tripId,
        fromName: 'Rahul',
        toName: 'Abhi',
        amountPaise: 150000,
      );

      var updatedTrip = repo.trips.firstWhere((t) => t.id == tripId);
      expect(updatedTrip.settlements.length, equals(1));
      expect(updatedTrip.settlements[0]['from'], equals('Rahul'));
      expect(updatedTrip.settlements[0]['to'], equals('Abhi'));
      expect(updatedTrip.settlements[0]['amountPaise'], equals(150000));

      // Delete/Undo settlement
      final settleId = updatedTrip.settlements[0]['id'];
      await repo.deleteTripSettlement(tripId, settleId);

      updatedTrip = repo.trips.firstWhere((t) => t.id == tripId);
      expect(updatedTrip.settlements, isEmpty);
    });
  });
}
