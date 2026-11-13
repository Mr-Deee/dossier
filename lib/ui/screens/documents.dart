import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/crypto/key_manager.dart';
import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/firebase_refs.dart';
import '../../core/services/vault_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';
import 'records.dart';

Future<PlatformFile?> _pick(BuildContext context) async {
  final r = await FilePicker.platform.pickFiles(withData: true);
  final f = r?.files.single;
  if (f == null) return null;
  if (f.bytes == null) {
    if (context.mounted) toast(context, 'Could not read that file.', error: true);
    return null;
  }
  return f;
}

/// Pick → encrypt on device → upload ciphertext → describe it.
Future<void> startDocumentUpload(BuildContext context, {String? relatedRecord}) async {
  final repo = context.read<VaultRepository>();
  final f = await _pick(context);
  if (f == null || !context.mounted) return;
  final meta = await runBusy(context, () => repo.uploadFile(bytes: f.bytes!, fileName: f.name),
      label: 'Encrypting and uploading ${f.name}…');
  if (meta == null || !context.mounted) return;
  final title = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
  final saved = await RecordFormScreen.open(context, Kinds.document, initial: {
    'title': title,
    'files': [meta],
    if (relatedRecord != null) 'relatedRecord': relatedRecord,
  });
  if (saved == null) {
    // User cancelled: remove the orphaned ciphertext.
    try {
      await Refs.storage.ref(Refs.filePath(repo.session.uid, Categories.vault, meta['fileId'] as String)).delete();
    } catch (_) {}
  }
}

Future<void> uploadNewVersion(BuildContext context, DossierRecord doc) async {
  final repo = context.read<VaultRepository>();
  final f = await _pick(context);
  if (f == null || !context.mounted) return;
  await runBusy(context, () async {
    final meta = await repo.uploadFile(bytes: f.bytes!, fileName: f.name);
    final data = Map<String, dynamic>.from(doc.data);
    data['files'] = [...VaultRepository.fileVersions(doc), meta];
    await repo.save(Kinds.document, data, id: doc.id);
  }, label: 'Encrypting new version…', success: 'New version saved');
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String? _cat;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final type = typeOf(Kinds.document);
    final all = repo.ofKind(Kinds.document);
    final cats = type.field('docCategory')!.options;
    final now = DateTime.now();
    final docs = all.where((d) {
      if (_cat != null && d.str('docCategory') != _cat) return false;
      if (_q.isEmpty) return true;
      return d.data.entries.where((e) => e.key != 'files').any((e) => e.value.toString().toLowerCase().contains(_q)) ||
          VaultRepository.fileVersions(d).any((f) => (f['fileName'] as String? ?? '').toLowerCase().contains(_q));
    }).toList();

    return Scaffold(
      appBar: AppBar(leading: const MenuButton(), leadingWidth: 68, toolbarHeight: 72, title: const Text('My Vault')),
      // Lift above the Shell's floating glass nav bar.
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: kShellNavClearance),
          child: FloatingActionButton.extended(
            onPressed: () => startDocumentUpload(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload'),
            backgroundColor: Brand.gold,
            foregroundColor: Brand.navy,
          )),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search documents'),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                    label: Text('All (${all.length})'),
                    selected: _cat == null,
                    onSelected: (_) => setState(() => _cat = null)),
              ),
              for (final c in cats)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$c (${all.where((d) => d.str('docCategory') == c).length})'),
                    selected: _cat == c,
                    onSelected: (_) => setState(() => _cat = _cat == c ? null : c),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          if (all.isEmpty)
            const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'Your vault is empty',
              message: 'Upload title deeds, Ghana Card, certificates, policies and statements. '
                  'Files are encrypted on this device before upload.',
            )
          else if (docs.isEmpty)
            const EmptyState(icon: Icons.search_off, title: 'No matching documents')
          else
            for (final d in docs)
              NavTile(
                icon: Icons.description_outlined,
                title: d.str('title'),
                subtitle: [
                  d.str('docCategory'),
                  if (d.date('expiryDate') != null)
                    d.date('expiryDate')!.isBefore(now)
                        ? 'EXPIRED ${fmtDate(d.date('expiryDate'))}'
                        : 'expires ${fmtDate(d.date('expiryDate'))}',
                  if (d.has('relatedRecord')) '→ ${repo.titleOf(d.str('relatedRecord'))}',
                ].where((x) => x.isNotEmpty).join('  ·  '),
                trailing: d.date('expiryDate') != null && d.date('expiryDate')!.isBefore(now)
                    ? const Icon(Icons.error_outline, color: Brand.danger)
                    : null,
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(recordId: d.id))),
              ),
        ],
      ),
    );
  }
}

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.recordId});
  final String recordId;
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<VaultRepository>();
    final d = repo.byId(recordId);
    return Stack(children: [
      RecordDetailScreen(recordId: recordId),
      if (d != null)
        Positioned(
          right: 16,
          bottom: 24,
          child: SafeArea(
            child: FloatingActionButton.extended(
              heroTag: 'newVersion',
              onPressed: () => uploadNewVersion(context, d),
              icon: const Icon(Icons.upload),
              label: const Text('New version'),
              backgroundColor: Brand.gold,
              foregroundColor: Brand.navy,
            ),
          ),
        ),
    ]);
  }
}
