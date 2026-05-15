class BackendConfig {
  const BackendConfig._();

  static const String scheme = 'http';
  static const String serverIp = '118.25.131.69';
  static const int serverPort = 8080;

  static String get baseUrl => '$scheme://$serverIp:$serverPort';

  static Uri uri(
    String path, [
    Map<String, Object?> queryParameters = const {},
  ]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final query = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value != null) {
        query[entry.key] = '$value';
      }
    }

    return Uri(
      scheme: scheme,
      host: serverIp,
      port: serverPort,
      path: normalizedPath,
      queryParameters: query.isEmpty ? null : query,
    );
  }
}
