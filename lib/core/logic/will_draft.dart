import 'package:intl/intl.dart';

import '../models/record.dart';
import '../schema/record_types.dart';
import 'analysis.dart';

const willDisclaimer =
    'THIS IS A DRAFT PREPARED FROM INFORMATION YOU ENTERED IN THE DOSSIER. IT IS NOT A VALID WILL. '
    'Under the Wills Act, 1971 (Act 360) a will must be in writing and signed by the testator (or by another person '
    'in their presence and by their direction) in the presence of two witnesses present at the same time, who also '
    'sign in the testator\'s presence. Have a qualified lawyer review this draft, then execute it properly. '
    'Beneficiary nominations on bank, pension and insurance products may take effect outside a will.';

/// Builds a structured, plain-language will draft from documented records.
String buildWillDraft(RecordIndex idx, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final b = StringBuffer();
  final profile = idx.ofKind(Kinds.profile).firstOrNull;
  final name = profile?.str('legalName').isNotEmpty == true ? profile!.str('legalName') : '[FULL LEGAL NAME]';
  final address = profile?.str('address').isNotEmpty == true ? profile!.str('address') : '[ADDRESS]';

  b.writeln('DRAFT — LAST WILL AND TESTAMENT');
  b.writeln('Generated ${DateFormat.yMMMMd().format(n)}');
  b.writeln();
  b.writeln('⚠ $willDisclaimer');
  b.writeln();
  b.writeln('1. DECLARATION');
  b.writeln('I, $name, of $address, being of sound mind, declare this to be my last will and testament, '
      'and I revoke all former wills and testamentary dispositions made by me.');
  b.writeln();

  // Executors
  final execs = idx.ofKind(Kinds.executor);
  String people(String role) => execs
      .where((e) => e.str('role') == role)
      .map((e) => '${e.str('name')}${e.has('relationship') ? ' (${e.str('relationship')})' : ''}')
      .join(' and ');
  b.writeln('2. EXECUTORS');
  final primary = people('Primary executor');
  final co = people('Co-executor');
  final alt = people('Alternative executor');
  b.writeln(primary.isEmpty
      ? 'I appoint [EXECUTOR NOT YET NOMINATED] as executor of this will.'
      : 'I appoint $primary${co.isEmpty ? '' : ' and $co'} as executor(s) of this will.');
  if (alt.isNotEmpty) {
    b.writeln('If any of them is unable or unwilling to act, I appoint $alt in their place.');
  }
  b.writeln();

  final guardians = people('Guardian of minor children');
  if (guardians.isNotEmpty) {
    b.writeln('3. GUARDIANSHIP');
    b.writeln('If any of my children is a minor at my death, I wish $guardians to be appointed guardian(s).');
    b.writeln();
  }

  // Specific gifts
  b.writeln('${guardians.isNotEmpty ? 4 : 3}. SPECIFIC GIFTS');
  final allocs = idx.ofKind(Kinds.allocation);
  var i = 1;
  for (final kind in Kinds.assets) {
    for (final asset in idx.ofKind(kind)) {
      final mine = allocs.where((a) => a.str('assetId') == asset.id).toList();
      if (mine.isEmpty && !asset.has('successionNotes')) continue;
      b.writeln('  ${i++}. ${_describeAsset(asset)}');
      for (final a in mine) {
        final ben = idx.byId(a.str('beneficiaryId'));
        final benText = ben == null ? '[deleted beneficiary]' : _describePerson(ben);
        final pct = (a.num_('percent') ?? 0);
        b.write('     — ${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2)}% to $benText');
        if (a.has('condition')) b.write(', ${a.str('condition')}');
        final alt = idx.byId(a.str('alternateId'));
        if (alt != null) b.write('; if they do not survive me, to ${_describePerson(alt)}');
        b.writeln('.');
      }
      if (asset.has('successionNotes')) b.writeln('     Instructions: ${asset.str('successionNotes')}');
    }
  }
  if (i == 1) b.writeln('  [No allocations recorded yet.]');
  b.writeln();

  b.writeln('RESIDUE');
  b.writeln('I give the rest of my estate, after payment of my just debts, funeral and testamentary expenses, to '
      '[RESIDUARY BENEFICIARY — to be confirmed with your lawyer].');
  b.writeln();

  final liabilities = idx.ofKind(Kinds.liability);
  if (liabilities.isNotEmpty) {
    b.writeln('KNOWN LIABILITIES (for the executor\'s information)');
    for (final l in liabilities) {
      b.writeln('  • ${l.str('name')} — ${l.str('creditor')}, ${money(l.num_('balance') ?? 0, l.str('currency').isEmpty ? 'GHS' : l.str('currency'))}');
    }
    b.writeln();
  }

  final wishes = idx.ofKind(Kinds.wish);
  if (wishes.isNotEmpty) {
    b.writeln('PERSONAL WISHES (not legally binding — included for guidance)');
    for (final w in wishes) {
      b.writeln('  • ${w.str('type')}: ${w.str('details')}');
    }
    b.writeln();
  }

  b.writeln('SIGNATURE');
  b.writeln('Signed by the testator ______________________   Date ____________');
  b.writeln();
  b.writeln('Signed by the testator in our presence, both present at the same time, and by us in the presence of the testator:');
  b.writeln('Witness 1: Name ____________ Address ____________ Signature ____________');
  b.writeln('Witness 2: Name ____________ Address ____________ Signature ____________');
  b.writeln('(A beneficiary, or the spouse of a beneficiary, should not act as a witness.)');
  return b.toString();
}

String _describeAsset(DossierRecord a) {
  final t = typeOf(a.kind);
  final parts = <String>[t.title(a)];
  if (a.has('location')) parts.add('located at ${a.str('location')}');
  if (a.has('institution')) parts.add('held with ${a.str('institution')}');
  if (a.has('registration') && a.kind == Kinds.vehicle) parts.add('registration ${a.str('registration')}');
  final own = a.num_('ownership') ?? 100;
  if (own < 100) parts.add('(my ${own.toStringAsFixed(0)}% interest)');
  return '${t.label}: ${parts.join(', ')}';
}

String _describePerson(DossierRecord p) =>
    '${p.str('name')}${p.has('relationship') ? ' (my ${p.str('relationship').toLowerCase()})' : ''}';
