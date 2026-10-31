class BackendConfig {
  const BackendConfig._();

  static const String scheme = 'https';

  /*
   * 后端实际挂在 card 子域上。
   * 裸域 clarkhub.cn 不做服务（连接直接失败），App 配成裸域就会
   * 一直报「无法连接服务」。
   */
  static const String host = 'card.clarkhub.cn';
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
