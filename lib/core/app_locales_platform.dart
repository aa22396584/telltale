/// Android 13+ per-app locales. Unregistered (iOS, desktop, tests) is not API 33.
///
/// `LocaleManager.applicationLocales` is the authority. An empty list means
/// follow the system — it is not English. Configuration tags after an override
/// are the override, not the original system list, and are never used to
/// invent one.
library;

import 'package:flutter/services.dart';

const kAppLocalesChannelName = 'com.cbstudio.telltale/app_locales';
const kAppLocalesGetMethod = 'getAppLocales';
const kAppLocalesSetMethod = 'setAppLocales';

final class AppLocalesSnapshot {
  const AppLocalesSnapshot({
    required this.apiSupported,
    required this.sdkInt,
    required this.followsSystem,
    required this.overrideTags,
    required this.configurationTags,
  });

  factory AppLocalesSnapshot.unsupported() => const AppLocalesSnapshot(
    apiSupported: false,
    sdkInt: null,
    followsSystem: true,
    overrideTags: [],
    configurationTags: [],
  );

  factory AppLocalesSnapshot.fromPlatformMap(Map<Object?, Object?> values) {
    return AppLocalesSnapshot(
      apiSupported: values['apiSupported'] == true,
      sdkInt: _intOrNull(values['sdkInt']),
      followsSystem: values['followsSystem'] != false,
      overrideTags: _stringList(values['overrideTags']),
      configurationTags: _stringList(values['configurationTags']),
    );
  }

  final bool apiSupported;
  final int? sdkInt;
  final bool followsSystem;
  final List<String> overrideTags;
  final List<String> configurationTags;
}

abstract final class AppLocalesPlatform {
  static MethodChannel channel = const MethodChannel(kAppLocalesChannelName);

  static Future<AppLocalesSnapshot> get() async {
    try {
      final raw = await channel.invokeMethod<Object?>(kAppLocalesGetMethod);
      if (raw is Map) {
        return AppLocalesSnapshot.fromPlatformMap(raw);
      }
      return AppLocalesSnapshot.unsupported();
    } on Object {
      return AppLocalesSnapshot.unsupported();
    }
  }

  /// Empty [tags] clears the override (follow system). Unknown tags fail.
  ///
  /// Returns the post-set snapshot, or unsupported when the host has no
  /// LocaleManager. A rejected tag list returns null.
  static Future<AppLocalesSnapshot?> setOverrideTags(List<String> tags) async {
    try {
      final raw = await channel.invokeMethod<Object?>(
        kAppLocalesSetMethod,
        <String, Object?>{'tags': tags},
      );
      if (raw is Map) {
        return AppLocalesSnapshot.fromPlatformMap(raw);
      }
      return AppLocalesSnapshot.unsupported();
    } on PlatformException catch (error) {
      if (error.code == 'unsupported_locale') return null;
      return AppLocalesSnapshot.unsupported();
    } on Object {
      return AppLocalesSnapshot.unsupported();
    }
  }
}

int? _intOrNull(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return null;
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is String && item.isNotEmpty) item,
  ];
}
