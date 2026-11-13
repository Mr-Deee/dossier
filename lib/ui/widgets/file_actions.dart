import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/vault_repository.dart';
import 'common.dart';

/// Decrypted files are written to a private temp folder only so the OS viewer
/// can open them, and the folder is purged whenever the vault locks or the
/// app starts.
Future<Directory> _openDir() async {
  final base = await getTemporaryDirectory();
  final d = Directory('${base.path}/dossier_open');
  if (!d.existsSync()) d.createSync(recursive: true);
  return d;
}

Future<void> purgeDecryptedTemp() async {
  try {
    final base = await getTemporaryDirectory();
    final d = Directory('${base.path}/dossier_open');
    if (d.existsSync()) d.deleteSync(recursive: true);
  } catch (_) {}
}

Future<void> openDecryptedFile(
  BuildContext context, {
  required String ownerUid,
  required String category,
  required Map<String, dynamic> fileMeta,
  VoidCallback? onOpened,
}) async {
  final bytes = await runBusy<Uint8List>(
    context,
    () => VaultRepository.downloadFile(ownerUid: ownerUid, category: category, fileMeta: fileMeta),
    label: 'Downloading and decrypting…',
  );
  if (bytes == null) return;
  final dir = await _openDir();
  final safe = (fileMeta['fileName'] as String? ?? 'document').replaceAll(RegExp(r'[^\w.\- ]'), '_');
  final f = File('${dir.path}/$safe');
  await f.writeAsBytes(bytes, flush: true);
  onOpened?.call();
  final r = await OpenFilex.open(f.path);
  if (r.type != ResultType.done && context.mounted) {
    toast(context, 'No app available to open ${fileMeta['fileName']}', error: true);
  }
}
