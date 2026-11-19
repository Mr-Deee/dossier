// On-device "Dossier Intelligence". Everything here runs locally over
// decrypted records; nothing is sent to any server or AI service.

import 'package:intl/intl.dart';

import '../models/record.dart';
import '../schema/record_types.dart';

class RecordIndex {
  RecordIndex(this.records) : _byId = {for (final r in records) r.id: r};
  final List<DossierRecord> records;
  final Map<String, DossierRecord> _byId;

  DossierRecord? byId(String? id) => id == null ? null : _byId[id];
  List<DossierRecord> ofKind(String k) => records.where((r) => r.kind == k).toList();
  List<DossierRecord> ofKinds(Iterable<String> ks) => records.where((r) => ks.contains(r.kind)).toList();
  String title(String? id) {
    final r = byId(id);
    return r == null ? '(missing record)' : typeOf(r.kind).title(r);
  }
}

// ---------------------------------------------------------------------------
// Net worth
// ---------------------------------------------------------------------------

class CurrencyTotals {
  double assets = 0;
  double liabilities = 0;
  final Map<String, double> byKind = {};
  double get net => assets - liabilities;
}

double assetShareValue(DossierRecord r) {
  final v = r.num_('value') ?? 0;
  final own = r.num_('ownership') ?? 100;
  return v * own.clamp(0, 100) / 100;
}

/// Totals grouped by currency (no FX conversion — values are user estimates).
Map<String, CurrencyTotals> netWorth(RecordIndex idx) {
  final out = <String, CurrencyTotals>{};
  CurrencyTotals t(String c) => out.putIfAbsent(c, CurrencyTotals.new);
  for (final r in idx.ofKinds(Kinds.assets)) {
    final c = r.str('currency').isEmpty ? 'GHS' : r.str('currency');
    final v = assetShareValue(r);
    t(c).assets += v;
    t(c).byKind[r.kind] = (t(c).byKind[r.kind] ?? 0) + v;
  }
  for (final r in idx.ofKind(Kinds.liability)) {
    final c = r.str('currency').isEmpty ? 'GHS' : r.str('currency');
    t(c).liabilities += r.num_('balance') ?? 0;
  }
  // What is still owed on assets being paid off in installments.
  for (final r in idx.ofKinds(Kinds.assets)) {
    final owed = outstandingBalance(r);
    if (owed == null || owed <= 0) continue;
    final c = r.str('currency').isEmpty ? 'GHS' : r.str('currency');
    t(c).liabilities += owed;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Installments
// ---------------------------------------------------------------------------

bool isPayingInstallments(DossierRecord r) => r.str('paymentStatus') == paymentInstallments;

/// The price the installments are paying off, if recorded.
double? totalPrice(DossierRecord r) => r.num_('acquisitionPrice') ?? r.num_('purchasePrice');

/// Balance still owed on an asset bought in installments: the recorded
/// balance, or else price minus amount paid. Null when fully paid or unknown.
double? outstandingBalance(DossierRecord r) {
  if (!isPayingInstallments(r)) return null;
  final b = r.num_('balance');
  if (b != null) return b < 0 ? 0 : b;
  final price = totalPrice(r);
  final paid = r.num_('amountPaid');
  if (price == null || paid == null) return null;
  final d = price - paid;
  return d < 0 ? 0 : d;
}

/// Share of the price already paid (0..1), when it can be worked out.
double? paidFraction(DossierRecord r) {
  final owed = outstandingBalance(r);
  if (owed == null) return null;
  final paid = r.num_('amountPaid');
  final total = totalPrice(r) ?? (paid == null ? null : paid + owed);
  if (total == null || total <= 0) return null;
  return ((total - owed) / total).clamp(0, 1).toDouble();
}

// ---------------------------------------------------------------------------
// Succession message timing
// ---------------------------------------------------------------------------

/// When a legacy message becomes readable to a confidant, given when their
/// access was released. Null means "as soon as access is released".
DateTime? messageOpensAt(DossierRecord r, {DateTime? releasedAt}) {
  switch (r.str('deliveryMode')) {
    case deliverOnDate:
      return r.date('deliverOn');
    case deliverAfterDelay:
      final n = (r.num_('delayAmount') ?? 0).round();
      if (n <= 0) return null;
      final from = releasedAt ?? DateTime.now();
      return switch (r.str('delayUnit')) {
        'Hours' => from.add(Duration(hours: n)),
        'Days' => from.add(Duration(days: n)),
        'Weeks' => from.add(Duration(days: 7 * n)),
        'Years' => DateTime(from.year + n, from.month, from.day, from.hour, from.minute),
        _ => DateTime(from.year, from.month + n, from.day, from.hour, from.minute),
      };
    default:
      return null;
  }
}

/// Human summary of a message's timing, e.g. "6 months after release".
String deliverySummary(DossierRecord r) {
  switch (r.str('deliveryMode')) {
    case deliverOnDate:
      final d = r.date('deliverOn');
      return d == null ? 'On a date (not set)' : 'Opens ${DateFormat.yMMMd().format(d)}';
    case deliverAfterDelay:
      final n = (r.num_('delayAmount') ?? 0).round();
      if (n <= 0) return 'When access is released';
      final unit = r.str('delayUnit').isEmpty ? 'Months' : r.str('delayUnit');
      final u = n == 1 ? unit.substring(0, unit.length - 1).toLowerCase() : unit.toLowerCase();
      return '$n $u after release';
    default:
      return 'When access is released';
  }
}

String money(double v, String currency) {
  final f = NumberFormat.decimalPattern();
  final rounded = v.abs() >= 100 ? v.roundToDouble() : v;
  return '$currency ${f.format(rounded)}';
}

// ---------------------------------------------------------------------------
// Reminders (Life Admin Guardian)
// ---------------------------------------------------------------------------

class Reminder {
  Reminder(this.record, this.label, this.date);
  final DossierRecord record;
  final String label;
  final DateTime date;
  int daysLeft(DateTime now) => DateTime(date.year, date.month, date.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
}

const _dateFields = {
  Kinds.document: ['expiryDate', 'expires'],
  Kinds.insurance: ['renewalDate', 'renews'],
  Kinds.vehicle: ['roadworthyExpiry', 'roadworthy/licence expires'],
  Kinds.liability: ['maturityDate', 'matures'],
};

List<Reminder> reminders(RecordIndex idx, {DateTime? now, int withinDays = 90}) {
  final n = now ?? DateTime.now();
  final out = <Reminder>[];
  _dateFields.forEach((kind, spec) {
    for (final r in idx.ofKind(kind)) {
      final d = r.date(spec[0]);
      if (d == null) continue;
      final rem = Reminder(r, '${typeOf(kind).title(r)} ${spec[1]}', d);
      if (rem.daysLeft(n) <= withinDays) out.add(rem);
    }
  });
  for (final r in idx.ofKinds(Kinds.assets).where(isPayingInstallments)) {
    final d = r.date('nextPaymentDate');
    if (d == null) continue;
    final rem = Reminder(r, '${typeOf(r.kind).title(r)} installment due', d);
    if (rem.daysLeft(n) <= withinDays) out.add(rem);
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

// ---------------------------------------------------------------------------
// Will health check
// ---------------------------------------------------------------------------

enum Severity { critical, warning, info }

class Issue {
  Issue(this.severity, this.message, {this.recordId});
  final Severity severity;
  final String message;
  final String? recordId;
}

Map<String, double> allocatedPercentByAsset(RecordIndex idx) {
  final out = <String, double>{};
  for (final a in idx.ofKind(Kinds.allocation)) {
    out[a.str('assetId')] = (out[a.str('assetId')] ?? 0) + (a.num_('percent') ?? 0);
  }
  return out;
}

List<Issue> willHealthCheck(RecordIndex idx, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final issues = <Issue>[];
  final assets = idx.ofKinds(Kinds.assets);
  final bens = idx.ofKind(Kinds.beneficiary);
  final allocs = idx.ofKind(Kinds.allocation);
  final executors = idx.ofKind(Kinds.executor);
  final pct = allocatedPercentByAsset(idx);

  if (assets.isEmpty) issues.add(Issue(Severity.critical, 'No assets documented yet.'));
  if (bens.isEmpty) issues.add(Issue(Severity.critical, 'No beneficiaries recorded.'));

  for (final a in assets) {
    final p = pct[a.id] ?? 0;
    final name = typeOf(a.kind).title(a);
    if (p == 0 && !a.has('successionNotes')) {
      issues.add(Issue(Severity.warning, '"$name" has no beneficiary instructions.', recordId: a.id));
    } else if (p > 100.0001) {
      issues.add(Issue(Severity.critical, '"$name" is allocated ${p.toStringAsFixed(1)}% — more than 100%.', recordId: a.id));
    } else if (p > 0 && p < 99.9999) {
      issues.add(Issue(Severity.info, '"$name" is only ${p.toStringAsFixed(1)}% allocated; the rest may pass under intestacy rules.', recordId: a.id));
    }
    final updated = a.updatedAt;
    if (updated != null && n.difference(updated).inDays > 365) {
      issues.add(Issue(Severity.info, 'Valuation of "$name" is over a year old.', recordId: a.id));
    }
    if ((a.num_('ownership') ?? 100) < 100 && !a.has('coOwners') && a.kind == Kinds.property) {
      issues.add(Issue(Severity.info, '"$name" is part-owned but co-owners are not listed.', recordId: a.id));
    }
  }

  final seen = <String>{};
  for (final al in allocs) {
    final key = '${al.str('assetId')}|${al.str('beneficiaryId')}';
    if (!seen.add(key)) {
      issues.add(Issue(Severity.warning,
          'Duplicate allocation of "${idx.title(al.str('assetId'))}" to ${idx.title(al.str('beneficiaryId'))}.',
          recordId: al.id));
    }
    if (idx.byId(al.str('assetId')) == null || idx.byId(al.str('beneficiaryId')) == null) {
      issues.add(Issue(Severity.warning, 'An allocation refers to a deleted asset or beneficiary.', recordId: al.id));
    }
    if (al.str('alternateId').isNotEmpty && al.str('alternateId') == al.str('beneficiaryId')) {
      issues.add(Issue(Severity.warning, 'An allocation names the same person as primary and alternative.', recordId: al.id));
    }
  }

  for (final b in bens) {
    final name = typeOf(Kinds.beneficiary).title(b);
    if (!b.has('phone') && !b.has('email') && !b.has('address')) {
      issues.add(Issue(Severity.info, 'No contact details for beneficiary $name.', recordId: b.id));
    }
    if (b.data['isMinor'] == true && !b.has('guardian')) {
      issues.add(Issue(Severity.warning, '$name is a minor but no guardian/trustee is named.', recordId: b.id));
    }
    if (!allocs.any((a) => a.str('beneficiaryId') == b.id)) {
      issues.add(Issue(Severity.info, '$name has not been allocated anything.', recordId: b.id));
    }
  }

  final primaries = executors.where((e) => e.str('role') == 'Primary executor').toList();
  if (primaries.isEmpty) {
    issues.add(Issue(Severity.critical, 'No primary executor nominated.'));
  } else {
    for (final e in primaries) {
      if (!e.has('phone') && !e.has('email')) {
        issues.add(Issue(Severity.warning, 'Executor ${e.str('name')} has no contact details.', recordId: e.id));
      }
      if (e.data['consented'] != true) {
        issues.add(Issue(Severity.info, 'Confirm that ${e.str('name')} has agreed to act as executor.', recordId: e.id));
      }
    }
  }
  if (!executors.any((e) => e.str('role') == 'Alternative executor')) {
    issues.add(Issue(Severity.info, 'Consider naming an alternative executor.'));
  }
  final hasMinors = bens.any((b) => b.data['isMinor'] == true) ||
      idx.ofKind(Kinds.familyMember).any((f) => f.str('relationship') == 'Child' && _isMinor(f.date('dateOfBirth'), n));
  if (hasMinors && !executors.any((e) => e.str('role') == 'Guardian of minor children')) {
    issues.add(Issue(Severity.warning, 'You have minor children/beneficiaries but no guardianship wishes recorded.'));
  }

  final drafts = idx.ofKind(Kinds.willVersion);
  if (drafts.isEmpty) {
    issues.add(Issue(Severity.warning, 'No will draft generated yet.'));
  } else if (!drafts.any((d) => d.str('status') == 'Signed and witnessed')) {
    issues.add(Issue(Severity.warning,
        'No draft is marked "Signed and witnessed". A draft is not a valid will until properly executed.'));
  }
  issues.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return issues;
}

bool _isMinor(DateTime? dob, DateTime now) {
  if (dob == null) return false;
  return now.difference(dob).inDays < 18 * 365.25;
}

// ---------------------------------------------------------------------------
// Legacy Readiness Index (documentation completeness, NOT legal security)
// ---------------------------------------------------------------------------

class ScoreItem {
  ScoreItem(this.label, this.points, this.max, this.hint);
  final String label;
  final double points;
  final double max;
  final String hint;
  bool get complete => points >= max - 0.001;
}

class Readiness {
  Readiness(this.items);
  final List<ScoreItem> items;
  int get score => items.fold<double>(0, (s, i) => s + i.points).round();
}

Readiness readiness(RecordIndex idx, {required int confidantGrants}) {
  final items = <ScoreItem>[];
  double ratio(int a, int b) => b == 0 ? 0 : (a / b).clamp(0, 1).toDouble();

  final profile = idx.ofKind(Kinds.profile).firstOrNull;
  const profileKeys = ['legalName', 'dateOfBirth', 'nationality', 'address', 'phone', 'maritalStatus'];
  final filled = profile == null ? 0 : profileKeys.where(profile.has).length;
  items.add(ScoreItem('Personal profile', 10 * ratio(filled, profileKeys.length), 10, 'Complete your legal name, date of birth, address and marital status.'));

  final assets = idx.ofKinds(Kinds.assets);
  items.add(ScoreItem('Assets documented', assets.isEmpty ? 0 : (assets.length >= 3 ? 10 : 6), 10, 'Add your properties, accounts, vehicles and businesses.'));

  final docs = idx.ofKind(Kinds.document);
  final withDocs = assets.where((a) => docs.any((d) => d.str('relatedRecord') == a.id)).length;
  items.add(ScoreItem('Assets with supporting documents', 15 * ratio(withDocs, assets.length), 15, 'Link title deeds, statements or receipts to each asset.'));

  final liabilitiesOrInsurance = idx.ofKinds([Kinds.liability, Kinds.insurance]).length;
  items.add(ScoreItem('Liabilities & insurance recorded', liabilitiesOrInsurance > 0 ? 5 : 0, 5, 'Record what you owe and your insurance policies.'));

  final bens = idx.ofKind(Kinds.beneficiary);
  items.add(ScoreItem('Beneficiaries named', bens.isEmpty ? 0 : 10, 10, 'Add the people or organisations who should inherit.'));

  final pct = allocatedPercentByAsset(idx);
  final allocated = assets.where((a) => (pct[a.id] ?? 0) > 0 || a.has('successionNotes')).length;
  items.add(ScoreItem('Assets with beneficiary instructions', 15 * ratio(allocated, assets.length), 15, 'Use the Will Builder to allocate each asset.'));

  final hasExecutor = idx.ofKind(Kinds.executor).any((e) => e.str('role') == 'Primary executor');
  items.add(ScoreItem('Executor nominated', hasExecutor ? 10 : 0, 10, 'Nominate a primary and an alternative executor.'));

  final drafts = idx.ofKind(Kinds.willVersion);
  final executed = drafts.any((d) => d.str('status') == 'Signed and witnessed');
  final reviewed = drafts.any((d) => d.str('status').contains('Reviewed') || d.str('status') == 'Signed and witnessed');
  items.add(ScoreItem('Will prepared', (drafts.isNotEmpty ? 4 : 0) + (reviewed ? 3 : 0) + (executed ? 3 : 0), 10,
      'Generate a draft, have a lawyer review it, then sign before two witnesses.'));

  items.add(ScoreItem('Trusted confidant with access', confidantGrants > 0 ? 10 : 0, 10, 'Name at least one confidant in My Succession.'));

  final wishesOrMessages = idx.ofKinds([Kinds.wish, Kinds.legacyMessage]).length;
  items.add(ScoreItem('Wishes & legacy messages', wishesOrMessages > 0 ? 5 : 0, 5, 'Record funeral wishes or a message for loved ones.'));
  return Readiness(items);
}

// ---------------------------------------------------------------------------
// Dossier Assistant — local intent matching
// ---------------------------------------------------------------------------

class AssistantAnswer {
  AssistantAnswer(this.text, [this.records = const []]);
  final String text;
  final List<DossierRecord> records;
}

const assistantSuggestions = [
  'What assets have I documented?',
  'What is my estimated net worth?',
  'Which documents expire soon?',
  'Which assets have no beneficiary?',
  'Which assets have no supporting documents?',
  'Which businesses have succession instructions?',
  'Who are my beneficiaries?',
  'What is missing from my will?',
];

AssistantAnswer ask(String question, RecordIndex idx, {int confidantGrants = 0}) {
  final q = question.toLowerCase();
  bool has(List<String> words) => words.any(q.contains);

  if (has(['net worth', 'worth', 'how much'])) {
    final nw = netWorth(idx);
    if (nw.isEmpty) return AssistantAnswer('You have not recorded any assets or liabilities yet.');
    final lines = nw.entries.map((e) =>
        '• ${e.key}: assets ${money(e.value.assets, e.key)} − liabilities ${money(e.value.liabilities, e.key)} = ${money(e.value.net, e.key)}');
    return AssistantAnswer(
        'Estimated net worth (your share, based on your own estimates — not verified valuations):\n${lines.join('\n')}');
  }
  if (has(['expir', 'renew', 'due soon', 'deadline'])) {
    final r = reminders(idx, withinDays: 120);
    if (r.isEmpty) return AssistantAnswer('Nothing expires or renews in the next 120 days.');
    final now = DateTime.now();
    return AssistantAnswer(
      r.map((x) => '• ${x.label} — ${DateFormat.yMMMd().format(x.date)} (${x.daysLeft(now) < 0 ? 'overdue' : 'in ${x.daysLeft(now)} days'})').join('\n'),
      r.map((x) => x.record).toList(),
    );
  }
  if (has(['no beneficiary', 'without beneficiary', 'unallocated', 'unassigned', 'no beneficiar'])) {
    final pct = allocatedPercentByAsset(idx);
    final list = idx.ofKinds(Kinds.assets).where((a) => (pct[a.id] ?? 0) == 0 && !a.has('successionNotes')).toList();
    return AssistantAnswer(
        list.isEmpty ? 'Every documented asset has beneficiary instructions.' : '${list.length} asset(s) have no beneficiary allocation:',
        list);
  }
  if (has(['supporting', 'missing document', 'no document', 'without document'])) {
    final docs = idx.ofKind(Kinds.document);
    final list = idx.ofKinds(Kinds.assets).where((a) => !docs.any((d) => d.str('relatedRecord') == a.id)).toList();
    return AssistantAnswer(
        list.isEmpty ? 'Every asset has at least one linked document.' : '${list.length} asset(s) have no linked supporting document:',
        list);
  }
  if (has(['business'])) {
    final b = idx.ofKind(Kinds.business);
    final withSucc = b.where((x) => x.has('successionNotes') || x.has('continuity')).toList();
    final without = b.where((x) => !withSucc.contains(x)).toList();
    return AssistantAnswer(
      'You have ${b.length} business interest(s). ${withSucc.length} have succession or continuity instructions'
      '${without.isEmpty ? '.' : '; these do not: ${without.map((x) => x.str('name')).join(', ')}.'}',
      b,
    );
  }
  if (has(['beneficiar', 'inherit', 'who gets'])) {
    final b = idx.ofKind(Kinds.beneficiary);
    return AssistantAnswer(b.isEmpty ? 'No beneficiaries recorded yet.' : 'You have ${b.length} beneficiaries:', b);
  }
  if (has(['will', 'missing', 'gap', 'ready', 'complete'])) {
    final issues = willHealthCheck(idx);
    final score = readiness(idx, confidantGrants: confidantGrants);
    final top = issues.where((i) => i.severity != Severity.info).take(8).map((i) => '• ${i.message}');
    return AssistantAnswer(
        'Legacy readiness: ${score.score}/100 (documentation completeness only).\n'
        '${top.isEmpty ? 'No critical gaps found.' : top.join('\n')}');
  }
  if (has(['polic', 'insur'])) {
    final p = idx.ofKind(Kinds.insurance);
    return AssistantAnswer(p.isEmpty ? 'No insurance policies recorded.' : 'You have ${p.length} insurance polic(ies):', p);
  }
  if (has(['owe', 'debt', 'liabilit', 'loan'])) {
    final l = idx.ofKind(Kinds.liability);
    return AssistantAnswer(l.isEmpty ? 'No liabilities recorded.' : 'You have ${l.length} recorded liabilities:', l);
  }
  if (has(['asset', 'own', 'property', 'properties'])) {
    final a = idx.ofKinds(Kinds.assets);
    final counts = <String, int>{};
    for (final x in a) {
      counts[typeOf(x.kind).plural] = (counts[typeOf(x.kind).plural] ?? 0) + 1;
    }
    return AssistantAnswer(
      a.isEmpty ? 'No assets documented yet.' : 'You have documented ${a.length} assets:\n${counts.entries.map((e) => '• ${e.key}: ${e.value}').join('\n')}',
      a,
    );
  }
  // Fallback: keyword search across decrypted fields.
  final terms = q.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
  final hits = idx.records
      .where((r) => r.kind != Kinds.allocation)
      .where((r) => terms.any((t) => r.data.values.any((v) => v.toString().toLowerCase().contains(t))))
      .take(20)
      .toList();
  return AssistantAnswer(
      hits.isEmpty
          ? 'I could not find anything matching that. Try one of the suggested questions.'
          : 'Records mentioning "${terms.join(' ')}":',
      hits);
}
