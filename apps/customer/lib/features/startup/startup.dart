import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/version.dart';
import '../../data/api_client.dart';

/// What the app learns from the API before anything else: business config and whether this
/// build is still supported.
class Startup {
  const Startup({required this.config, required this.installedVersion, this.version});

  final PublicConfigDto config;
  final String installedVersion;
  final AppVersionDto? version;

  /// Below the minimum version: the app must be updated before it can be used.
  bool get updateRequired => version != null && compareVersions(installedVersion, version!.minVersion) < 0;

  /// A newer version exists but this one still works.
  bool get updateAvailable => version != null && compareVersions(installedVersion, version!.latestVersion) < 0;
}

final startupProvider = FutureProvider<Startup>((ref) async {
  final api = ref.watch(apiProvider);
  final platform = Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
  try {
    final results = await Future.wait<Object?>([
      api.config.publicConfigControllerGet(),
      api.appVersions.appVersionsControllerGet(app: ClientApp.customer, platform: platform),
      PackageInfo.fromPlatform(),
    ], eagerError: true);
    final rawVersion = results[1];
    return Startup(
      config: results[0]! as PublicConfigDto,
      installedVersion: (results[2]! as PackageInfo).version,
      // The API answers null when no versions are configured for this app.
      version: rawVersion is Map<String, Object?> ? AppVersionDto.fromJson(rawVersion) : null,
    );
  } catch (e) {
    throw ApiFailure.from(e);
  }
});
