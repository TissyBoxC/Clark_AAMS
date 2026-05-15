class AppVersionInfo {
  const AppVersionInfo({
    required this.currentVersion,
    required this.currentBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.updateType,
    required this.updateAvailable,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.releaseNotes,
    required this.downloadSources,
    required this.releasePageUrl,
  });

  final String currentVersion;
  final int? currentBuild;
  final String latestVersion;
  final int? latestBuild;
  final String updateType;
  final bool updateAvailable;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> releaseNotes;
  final List<DownloadSource> downloadSources;
  final String releasePageUrl;

  DownloadSource? get primaryDownloadSource {
    for (final source in downloadSources) {
      if (source.primary) {
        return source;
      }
    }
    return downloadSources.isEmpty ? null : downloadSources.first;
  }

  static AppVersionInfo fromJson(Map<String, Object?> json) {
    final notes = json['releaseNotes'];
    final sources = json['downloadSources'];
    return AppVersionInfo(
      currentVersion: json['currentVersion'] as String? ?? '',
      currentBuild: _asInt(json['currentBuild']),
      latestVersion: json['latestVersion'] as String? ?? '',
      latestBuild: _asInt(json['latestBuild']),
      updateType: json['updateType'] as String? ?? 'none',
      updateAvailable: json['updateAvailable'] as bool? ?? false,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      title: json['title'] as String? ?? '发现新版本',
      message: json['message'] as String? ?? '',
      releaseNotes: notes is List
          ? notes.whereType<String>().toList()
          : const [],
      downloadSources: sources is List
          ? [
              for (final item in sources)
                if (item is Map<String, Object?>)
                  DownloadSource.fromJson(item)
                else if (item is Map)
                  DownloadSource.fromJson(item.cast<String, Object?>()),
            ]
          : const <DownloadSource>[],
      releasePageUrl: json['releasePageUrl'] as String? ?? '',
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class DownloadSource {
  const DownloadSource({
    required this.type,
    required this.label,
    required this.url,
    required this.primary,
    required this.description,
  });

  final String type;
  final String label;
  final String url;
  final bool primary;
  final String description;

  static DownloadSource fromJson(Map<String, Object?> json) {
    return DownloadSource(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      url: json['url'] as String? ?? '',
      primary: json['primary'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }
}
