/// Converts backend relative paths like "/uploads/..." into absolute URLs
/// using the same host as Dio baseUrl.
/// Example:
/// baseUrl = http://192.168.1.4:8080/api
/// path    = /uploadsPublish/publish/3/icon/x.jpg
/// result  = http://192.168.1.4:8080/uploadsPublish/publish/3/icon/x.jpg
String serverRootNoApiFromBaseUrl(String baseUrl) {
  // remove trailing "/api" or "/api/"
  return baseUrl
      .replaceFirst(RegExp(r'/api/?$'), '')
      .replaceAll(RegExp(r'/$'), '');
}

String absUrlFromServerRoot(String serverRootNoApi, String? maybe) {
  if (maybe == null) return '';
  final s = maybe.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;

  final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
  final rel = s.startsWith('/') ? s : '/$s';
  return '$base$rel';
}

/// Convenience: you pass Dio baseUrl directly
String absUrlFromDioBaseUrl(String dioBaseUrl, String? maybe) {
  final root = serverRootNoApiFromBaseUrl(dioBaseUrl);
  return absUrlFromServerRoot(root, maybe);
}
