import 'package:dossier/core/schema/record_types.dart';
import 'package:dossier/ui/theme.dart';
import 'package:dossier/ui/widgets/record_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpForm(WidgetTester t, String kind, Map<String, dynamic> initial) async {
    t.view.physicalSize = const Size(1179, 8000);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: buildTheme(Brightness.light), home: RecordFormScreen(key: UniqueKey(), kind: kind, initial: initial)));
    await t.pump(const Duration(milliseconds: 500));
  }

  testWidgets('land shows balance fields only while paying in installments', (t) async {
    await pumpForm(t, Kinds.property, {'paymentStatus': paymentFullyPaid});
    expect(find.text('Outstanding balance'), findsNothing);
    await pumpForm(t, Kinds.property, {'paymentStatus': paymentInstallments});
    expect(find.text('Outstanding balance'), findsOneWidget);
    expect(find.text('Amount paid so far'), findsOneWidget);
    expect(find.text('Next payment due'), findsOneWidget);
  });

  testWidgets('message shows delay or date fields for the chosen timing', (t) async {
    await pumpForm(t, Kinds.legacyMessage, {'deliveryMode': deliverAfterDelay});
    expect(find.text('How long after release'), findsOneWidget);
    expect(find.text('Open on'), findsNothing);
    await pumpForm(t, Kinds.legacyMessage, {'deliveryMode': deliverOnDate});
    expect(find.text('Open on'), findsOneWidget);
    expect(find.text('How long after release'), findsNothing);
  });
}
