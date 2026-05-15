class BackendConfig {
  const BackendConfig._();

  static const String scheme = 'https';
  static const String host = 'clarkhub.cn';
  static const int? serverPort = null;

  static String get baseUrl => '$scheme://$host';

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
      host: host,
      port: serverPort,
      path: normalizedPath,
      queryParameters: query.isEmpty ? null : query,
    );
  }
}
