/// A decrypted Dossier record held in memory only while the vault is unlocked.
class DossierRecord {
  DossierRecord({
    required this.id,
    required this.kind,
    required this.category,
    required this.data,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String kind;
  final String category;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String str(String key) => (data[key] ?? '').toString().trim();

  double? num_(String key) {
    final v = data[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  DateTime? date(String key) {
    final v = data[key];
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  List<String> list(String key) {
    final v = data[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  bool has(String key) {
    final v = data[key];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  DossierRecord copyWith({Map<String, dynamic>? data}) => DossierRecord(
        id: id,
        kind: kind,
        category: category,
        data: data ?? Map<String, dynamic>.from(this.data),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
