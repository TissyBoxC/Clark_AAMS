import 'dart:convert';

/// JSON 解析的统一入口。
///
/// **为什么需要这个文件**：代码库里原本散落 19 处同一种写法——
///
/// ```dart
/// if (value is Map<String, Object?>) { ... }
/// else if (value is Map) { ... value.cast<String, Object?>() ... }
/// ```
///
/// 原因是 `jsonDecode` 返回 `Map<String, dynamic>`，而业务代码要的是
/// `Map<String, Object?>`，两者不是同一类型，只能靠运行时判断加转换。
/// 每处都手写这段样板，既啰嗦，又容易在某处漏掉分支而静默丢弃数据。
///
/// 这里只做一件事：把「值可能是什么形状」的判定收敛到一处。
class JsonUtil {
  const JsonUtil._();

  /// 解码 JSON 字符串；解不开或不是对象/数组时返回 null（不抛异常）。
  static Object? tryDecode(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// 把任意值转成 `Map<String, Object?>`；不是对象时返回 null。
  ///
  /// 兼容 `Map<String, dynamic>`、`Map<dynamic, dynamic>` 等所有 Map 形态。
  static Map<String, Object?>? asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return null;
  }

  /// 把任意值转成 `List<Object?>`；不是数组时返回 null。
  static List<Object?>? asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    return null;
  }

  /// 把数组里的每个元素转成 Map，跳过不是对象的项。
  ///
  /// 这个分支最容易被漏写：只处理 `Map<String, Object?>`
  /// 而漏掉普通 `Map`，会导致整条数据被静默丢掉。
  static List<Map<String, Object?>> asMapList(Object? value) {
    final list = asList(value);
    if (list == null) {
      return const [];
    }
    final result = <Map<String, Object?>>[];
    for (final item in list) {
      final map = asMap(item);
      if (map != null) {
        result.add(map);
      }
    }
    return result;
  }

  /// 取整数字段，兼容 int / double / 数字字符串。
  static int? asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  /// 取字符串字段，null 转空串并去首尾空白。
  static String asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  /// 取布尔字段，兼容 `"true"` / `1` 这类松散表示。
  static bool asBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return fallback;
  }

  /// 把对象编码成便于人阅读的 JSON（调试与导出用）。
  static String prettyEncode(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
