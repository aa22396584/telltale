/// Software locale-bridge checks. This is not an OS process recreation.
///
/// Real LocaleManager activity recreation, API 32 device persistence, and
/// Settings → app language are not-run here. Drive those on an identified
/// device via #28.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';

void main() {
  test('a Dart resume plan is not an OS restart', () {
    final plan = planSync(
      apiSupported: true,
      alreadyMigrated: false,
      followsSystem: true,
      osOverrideTags: const [],
      storedId: 'en',
    );
    expect(plan.action, AppLocalesSyncAction.handoffStoredOnce);
    expect(plan.writeOs, isTrue);
  });

  test('after migrate, stored cannot overwrite a later OS selection', () {
    final plan = planSync(
      apiSupported: true,
      alreadyMigrated: true,
      followsSystem: false,
      osOverrideTags: const ['zh-Hant'],
      storedId: 'en',
    );
    expect(plan.writeOs, isFalse);
    expect(plan.storedIdToKeep, 'zh_Hant');
  });
}
