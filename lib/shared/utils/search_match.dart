bool searchMatch(String q, List<String?> fields) {
  final query = q.trim().toLowerCase();
  if (query.isEmpty) return true;

  for (final f in fields) {
    final v = (f ?? '').toLowerCase();
    if (v.contains(query)) return true;
  }
  return false;
}
