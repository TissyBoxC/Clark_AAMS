import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version.dart';
import '../resources/app_strings.dart';
import '../services/clark_backend_api.dart';
import '../widgets/top_bar.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _fallbackUpdateUrl = 'https://github.com/TissyBoxC/Clark_AAMS';

  PackageInfo? _packageInfo;
  AppVersionInfo? _versionInfo;
  String? _versionError;
  bool _checkingVersion = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: AppStrings.aboutTitle,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 108,
                      height: 108,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(AppStrings.appDescription),
                const SizedBox(height: 22),
                _VersionPanel(
                  packageInfo: _packageInfo,
                  versionInfo: _versionInfo,
                  error: _versionError,
                  checking: _checkingVersion,
                  onCheck: _loadVersionInfo,
                  onUpdate: _openUpdateUrl,
                ),
                const SizedBox(height: 22),
                const _AboutRow(
                  label: AppStrings.authorLabel,
                  value: 'Provias',
                ),
                const _AboutRow(
                  label: AppStrings.licenseLabel,
                  value: AppStrings.gplLicense,
                ),
                const _AboutRow(
                  label: AppStrings.authorQqLabel,
                  value: '1686886163',
                ),
                const _AboutRow(
                  label: AppStrings.groupQqLabel,
                  value: '1046151390',
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.repositoryLabel,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const SelectableText(_fallbackUpdateUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadVersionInfo() async {
    if (_checkingVersion) {
      return;
    }
    setState(() {
      _checkingVersion = true;
      _versionError = null;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionInfo = await ClarkBackendApi.instance.checkVersion(
        platform: Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : Platform.operatingSystem,
        currentVersion: packageInfo.version,
        currentBuild: int.tryParse(packageInfo.buildNumber),
        channel: 'stable',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _packageInfo = packageInfo;
        _versionInfo = versionInfo;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _versionError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _checkingVersion = false);
      }
    }
  }

  Future<void> _openUpdateUrl() async {
    if (_versionInfo == null && !_checkingVersion) {
      await _loadVersionInfo();
    }
    final source = _versionInfo?.primaryDownloadSource;
    final url = source?.url.isNotEmpty == true
        ? source!.url
        : (_versionInfo?.releasePageUrl.isNotEmpty == true
              ? _versionInfo!.releasePageUrl
              : _fallbackUpdateUrl);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _VersionPanel extends StatelessWidget {
  const _VersionPanel({
    required this.packageInfo,
    required this.versionInfo,
    required this.error,
    required this.checking,
    required this.onCheck,
    required this.onUpdate,
  });

  final PackageInfo? packageInfo;
  final AppVersionInfo? versionInfo;
  final String? error;
  final bool checking;
  final VoidCallback onCheck;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final current = packageInfo == null
        ? AppStrings.loading
        : '${packageInfo!.version}+${packageInfo!.buildNumber}';
    final latest = versionInfo == null
        ? (checking ? AppStrings.checking : AppStrings.unknown)
        : _versionLabel(versionInfo!.latestVersion, versionInfo!.latestBuild);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.versionInfo,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _AboutRow(label: AppStrings.currentVersion, value: current),
          _AboutRow(label: AppStrings.latestVersion, value: latest),
          Text(
            error == null ? _statusText() : AppStrings.checkFailed(error!),
            style: TextStyle(
              color: error == null ? const Color(0xff6b4f5a) : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: checking ? null : onCheck,
                icon: checking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text(AppStrings.checkUpdate),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text(AppStrings.manualUpdate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText() {
    final info = versionInfo;
    if (info == null) {
      return checking
          ? AppStrings.checkingLatestVersion
          : AppStrings.noLatestVersion;
    }
    if (info.forceUpdate || info.updateType == 'required') {
      return AppStrings.currentVersionTooLow;
    }
    if (info.updateAvailable) {
      return AppStrings.newVersionAvailable;
    }
    return AppStrings.alreadyLatestVersion;
  }

  String _versionLabel(String version, int? build) {
    if (version.isEmpty) {
      return AppStrings.unknown;
    }
    return build == null ? version : '$version+$build';
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff6b4f5a),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
