import 'package:dossier/core/logic/analysis.dart';
import 'package:dossier/core/logic/will_draft.dart';
import 'package:dossier/core/models/record.dart';
import 'package:dossier/core/schema/record_types.dart';
import 'package:flutter_test/flutter_test.dart';

DossierRecord rec(String id, String kind, Map<String, dynamic> data) =>
    DossierRecord(id: id, kind: kind, category: typeOf(kind).category, data: data, updatedAt: DateTime.now());

void main() {
  final house = rec('h', Kinds.property, {'name': 'East Legon house', 'value': 2000000.0, 'currency': 'GHS', 'ownership': 50.0});
  final car = rec('c', Kinds.vehicle, {'name': 'Toyota Corolla', 'value': 150000.0, 'currency': 'GHS'});
  final usd = rec('u', Kinds.financialAccount, {'name': 'USD savings', 'institution': 'Bank', 'value': 10000.0, 'currency': 'USD'});
  final loan = rec('l', Kinds.liability, {'name': 'Car loan', 'creditor': 'Bank', 'balance': 50000.0, 'currency': 'GHS'});
  final ama = rec('b1', Kinds.beneficiary, {'name': 'Ama', 'relationship': 'Child', 'isMinor': true});
  final kofi = rec('b2', Kinds.beneficiary, {'name': 'Kofi', 'relationship': 'Sibling', 'phone': '020'});

  test('net worth uses ownership share and groups by currency', () {
    final nw = netWorth(RecordIndex([house, car, usd, loan]));
    expect(nw['GHS']!.assets, 1000000 + 150000);
    expect(nw['GHS']!.liabilities, 50000);
    expect(nw['GHS']!.net, 1100000);
    expect(nw['USD']!.net, 10000);
  });

  test('health check flags over-allocation, duplicates, minors without guardian, missing executor', () {
    final idx = RecordIndex([
      house, car, ama, kofi,
      rec('a1', Kinds.allocation, {'assetId': 'h', 'beneficiaryId': 'b1', 'percent': 70.0}),
      rec('a2', Kinds.allocation, {'assetId': 'h', 'beneficiaryId': 'b1', 'percent': 40.0}),
    ]);
    final msgs = willHealthCheck(idx).map((i) => i.message).join('\n');
    expect(msgs, contains('more than 100%'));
    expect(msgs, contains('Duplicate allocation'));
    expect(msgs, contains('Toyota Corolla" has no beneficiary instructions'));
    expect(msgs, contains('Ama is a minor'));
    expect(msgs, contains('No primary executor'));
  });

  test('readiness score is bounded 0..100', () {
    expect(readiness(RecordIndex([]), confidantGrants: 0).score, 0);
    final r = readiness(RecordIndex([house, car, usd, loan, ama]), confidantGrants: 1);
    expect(r.score, inInclusiveRange(1, 100));
  });

  test('reminders include expiring documents', () {
    final soon = DateTime.now().add(const Duration(days: 10)).toIso8601String().substring(0, 10);
    final doc = rec('d', Kinds.document, {'title': 'Passport', 'expiryDate': soon});
    final r = reminders(RecordIndex([doc]));
    expect(r.single.label, contains('Passport'));
  });

  test('assistant answers net worth and unallocated assets', () {
    final idx = RecordIndex([house, car, loan]);
    expect(ask('What is my net worth?', idx).text, contains('GHS'));
    expect(ask('Which assets have no beneficiary?', idx).records.length, 2);
  });

  test('will draft contains disclaimer, allocations and witness block', () {
    final idx = RecordIndex([
      house, kofi,
      rec('e', Kinds.executor, {'name': 'Esi Mensah', 'role': 'Primary executor'}),
      rec('a', Kinds.allocation, {'assetId': 'h', 'beneficiaryId': 'b2', 'percent': 100.0}),
    ]);
    final text = buildWillDraft(idx);
    expect(text, contains('NOT A VALID WILL'));
    expect(text, contains('Esi Mensah'));
    expect(text, contains('100% to Kofi'));
    expect(text, contains('Witness 2'));
  });
}
