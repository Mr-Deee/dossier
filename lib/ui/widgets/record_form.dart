import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/record.dart';
import '../../core/schema/record_types.dart';
import '../../core/services/vault_repository.dart';
import 'common.dart';

/// Generic add/edit form for any [RecordType]. Saving encrypts on device.
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, required this.kind, this.existing, this.initial, this.onSaved});

  final String kind;
  final DossierRecord? existing;
  final Map<String, dynamic>? initial;
  final void Function(DossierRecord saved)? onSaved;

  static Future<DossierRecord?> open(BuildContext context, String kind,
      {DossierRecord? existing, Map<String, dynamic>? initial}) {
    return Navigator.of(context).push<DossierRecord>(MaterialPageRoute(
      builder: (_) => RecordFormScreen(kind: kind, existing: existing, initial: initial),
      fullscreenDialog: true,
    ));
  }

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RecordType type = typeOf(widget.kind);
  late final Map<String, dynamic> values;
  final Map<String, TextEditingController> _ctrl = {};
  bool _saving = false;

  static const _textTypes = {
    FieldType.text,
    FieldType.multiline,
    FieldType.number,
    FieldType.money,
    FieldType.percent,
    FieldType.email,
    FieldType.phone,
  };

  @override
  void initState() {
    super.initState();
    values = {
      if (widget.existing == null)
        for (final f in type.fields)
          if (f.defaultValue != null) f.key: f.defaultValue,
      ...?widget.existing?.data,
      ...?widget.initial,
    };
    for (final f in type.fields.where((f) => _textTypes.contains(f.type))) {
      final v = values[f.key];
      _ctrl[f.key] = TextEditingController(text: v == null ? '' : _numText(v));
    }
  }

  String _numText(Object v) {
    if (v is double && v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    for (final f in type.fields.where((f) => _textTypes.contains(f.type))) {
      final t = _ctrl[f.key]!.text.trim();
      if ({FieldType.number, FieldType.money, FieldType.percent}.contains(f.type)) {
        values[f.key] = t.isEmpty ? null : double.tryParse(t.replaceAll(',', ''));
      } else {
        values[f.key] = t;
      }
    }
    // Drop answers to questions that no longer apply (e.g. switched back to "Fully paid").
    for (final f in type.fields) {
      if (!f.visibleWith(values)) values[f.key] = null;
    }
    setState(() => _saving = true);
    try {
      final repo = context.read<VaultRepository>();
      final saved = await repo.save(widget.kind, values, id: widget.existing?.id);
      if (!mounted) return;
      widget.onSaved?.call(saved);
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add ${type.label.toLowerCase()}' : 'Edit ${type.label.toLowerCase()}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_outline),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (type.description != null) ...[InfoBanner(type.description!), const SizedBox(height: 16)],
            for (final f in type.fields)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: f.visibleWith(values)
                    ? Padding(padding: const EdgeInsets.only(bottom: 14), child: _field(f))
                    : const SizedBox(width: double.infinity),
              ),
            const SizedBox(height: 8),
            const InfoBanner('Encrypted on this device before it is saved. The server only stores ciphertext.',
                icon: Icons.lock_outline),
          ],
        ),
      ),
    );
  }

  String? _validate(FieldSpec f, String? v) {
    final t = (v ?? '').trim();
    if (f.required && t.isEmpty) return '${f.label} is required';
    if (t.isEmpty) return null;
    switch (f.type) {
      case FieldType.email:
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Enter a valid email';
      case FieldType.number:
      case FieldType.money:
        if (double.tryParse(t.replaceAll(',', '')) == null) return 'Enter a number';
      case FieldType.percent:
        final p = double.tryParse(t);
        if (p == null || p < 0 || p > 100) return 'Enter a percentage from 0 to 100';
      default:
        break;
    }
    return null;
  }

  Widget _field(FieldSpec f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.type) {
      case FieldType.text:
      case FieldType.email:
      case FieldType.phone:
      case FieldType.multiline:
      case FieldType.number:
      case FieldType.money:
      case FieldType.percent:
        final numeric = {FieldType.number, FieldType.money, FieldType.percent}.contains(f.type);
        return TextFormField(
          controller: _ctrl[f.key],
          decoration: InputDecoration(
            labelText: label,
            hintText: f.hint,
            suffixText: f.type == FieldType.percent ? '%' : null,
            alignLabelWithHint: f.type == FieldType.multiline,
          ),
          minLines: f.type == FieldType.multiline ? 3 : 1,
          maxLines: f.type == FieldType.multiline ? 8 : 1,
          keyboardType: switch (f.type) {
            FieldType.email => TextInputType.emailAddress,
            FieldType.phone => TextInputType.phone,
            FieldType.multiline => TextInputType.multiline,
            _ when numeric => const TextInputType.numberWithOptions(decimal: true),
            _ => TextInputType.text,
          },
          inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
          textCapitalization:
              f.type == FieldType.text || f.type == FieldType.multiline ? TextCapitalization.sentences : TextCapitalization.none,
          validator: (v) => _validate(f, v),
        );
      case FieldType.date:
        final picked0 = values[f.key] is String ? DateTime.tryParse(values[f.key] as String) : null;
        return FormField<String>(
          initialValue: values[f.key] as String?,
          validator: (v) => f.required && (v == null || v.isEmpty) ? '${f.label} is required' : null,
          builder: (state) => InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: picked0 ?? DateTime.now(),
                firstDate: DateTime(1850),
                lastDate: DateTime(2150),
              );
              if (picked != null) {
                final iso = DateFormat('yyyy-MM-dd').format(picked);
                setState(() => values[f.key] = iso);
                state.didChange(iso);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                errorText: state.errorText,
                suffixIcon: picked0 == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => values.remove(f.key));
                          state.didChange(null);
                        },
                      ),
              ),
              child: Text(picked0 == null ? 'Select date' : fmtDate(picked0)),
            ),
          ),
        );
      case FieldType.choice:
        final choice = values[f.key] as String?;
        final choices = [...f.options, if (choice != null && !f.options.contains(choice)) choice];
        return DropdownButtonFormField<String>(
          initialValue: choice,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [for (final o in choices) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => values[f.key] = v),
          validator: (v) => f.required && v == null ? '${f.label} is required' : null,
        );
      case FieldType.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: values[f.key] == true,
          onChanged: (v) => setState(() => values[f.key] = v),
        );
      case FieldType.ref:
        final repo = context.watch<VaultRepository>();
        final linkable = repo.ofKinds(f.refKinds).where((r) => r.id != widget.existing?.id).toList();
        final linked = values[f.key] as String?;
        final valid = linkable.any((o) => o.id == linked) ? linked : null;
        return DropdownButtonFormField<String>(
          initialValue: valid,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            helperText: linkable.isEmpty ? 'Nothing to link yet' : null,
          ),
          items: [
            if (!f.required) const DropdownMenuItem<String>(value: null, child: Text('— None —')),
            for (final o in linkable)
              DropdownMenuItem(
                value: o.id,
                child: Text('${typeOf(o.kind).title(o)}  ·  ${typeOf(o.kind).label}', overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => values[f.key] = v),
          validator: (v) => f.required && v == null ? '${f.label} is required' : null,
        );
    }
  }
}
