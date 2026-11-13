import 'package:dossier/core/logic/analysis.dart';
import 'package:dossier/core/models/record.dart';
import 'package:dossier/core/schema/record_types.dart';
import 'package:flutter_test/flutter_test.dart';

DossierRecord rec(String id, String kind, Map<String, dynamic> data) =>
    DossierRecord(id: id, kind: kind, category: typeOf(kind).category, data: data, updatedAt: DateTime.now());

void main() {
  group('installments', () {
    final land = rec('land', Kinds.property, {
      'name': 'Plot at Oyarifa',
      'propertyType': 'Land',
      'acquisitionPrice': 120000.0,
      'value': 150000.0,
      'currency': 'GHS',
      'paymentStatus': paymentInstallments,
      'amountPaid': 45000.0,
    });

    test('balance is worked out from price minus amount paid when left blank', () {
      expect(outstandingBalance(land), 75000);
      expect(paidFraction(land), closeTo(0.375, 1e-9));
    });

    test('an entered balance wins over the calculation', () {
      final r = land.copyWith(data: {...land.data, 'balance': 70000.0});
      expect(outstandingBalance(r), 70000);
    });

    test('fully paid assets have no balance', () {
      final r = land.copyWith(data: {...land.data, 'paymentStatus': paymentFullyPaid});
      expect(outstandingBalance(r), isNull);
    });

    test('the balance still owed counts as a liability in net worth', () {
      final nw = netWorth(RecordIndex([land]));
      expect(nw['GHS']!.assets, 150000);
      expect(nw['GHS']!.liabilities, 75000);
      expect(nw['GHS']!.net, 75000);
    });

    test('next installment date becomes a reminder', () {
      final now = DateTime(2026, 11, 13);
      final r = land.copyWith(data: {...land.data, 'nextPaymentDate': '2026-12-01'});
      final rem = reminders(RecordIndex([r]), now: now);
      expect(rem.single.label, 'Plot at Oyarifa installment due');
    });

    test('installment fields only show while paying in installments', () {
      final f = typeOf(Kinds.property).field('balance')!;
      expect(f.visibleWith({'paymentStatus': paymentInstallments}), isTrue);
      expect(f.visibleWith({'paymentStatus': paymentFullyPaid}), isFalse);
    });
  });

  group('succession message timing', () {
    final released = DateTime(2030, 1, 15);
    DossierRecord msg(Map<String, dynamic> d) =>
        rec('m', Kinds.legacyMessage, {'title': 'Hello', 'recipient': 'Ama', 'message': '…', ...d});

    test('default opens as soon as access is released', () {
      final m = msg({'deliveryMode': deliverOnRelease});
      expect(messageOpensAt(m, releasedAt: released), isNull);
      expect(deliverySummary(m), 'When access is released');
    });

    test('a set time after release', () {
      final m = msg({'deliveryMode': deliverAfterDelay, 'delayAmount': 6.0, 'delayUnit': 'Months'});
      expect(messageOpensAt(m, releasedAt: released), DateTime(2030, 7, 15));
      expect(deliverySummary(m), '6 months after release');
      final w = msg({'deliveryMode': deliverAfterDelay, 'delayAmount': 1.0, 'delayUnit': 'Weeks'});
      expect(messageOpensAt(w, releasedAt: released), DateTime(2030, 1, 22));
      expect(deliverySummary(w), '1 week after release');
    });

    test('on a specific date', () {
      final m = msg({'deliveryMode': deliverOnDate, 'deliverOn': '2034-03-14'});
      expect(messageOpensAt(m, releasedAt: released), DateTime(2034, 3, 14));
      expect(deliverySummary(m), startsWith('Opens '));
    });
  });
}
