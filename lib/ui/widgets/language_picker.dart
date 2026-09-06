/// Language preference control. Self-named options, no flags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/locale_resolution.dart';
import '../../state/locale_settings.dart';

String localePreferenceLabel(LocalePreference preference) {
  return switch (preference) {
    LocalePreference.english => 'English',
    LocalePreference.traditionalChinese => '繁體中文',
    LocalePreference.system => 'System default / 跟隨系統',
  };
}

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({this.showHeading = true, super.key});

  final bool showHeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localePreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            l10n.languageSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        for (final value in LocalePreference.values)
          ListTile(
            key: Key('locale_${value.name}'),
            contentPadding: EdgeInsets.zero,
            title: Text(localePreferenceLabel(value)),
            leading: Icon(
              current == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            selected: current == value,
            onTap: () async {
              final ok = await ref
                  .read(localePreferenceProvider.notifier)
                  .set(value);
              if (!context.mounted || ok) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.languageSaveFailed)));
            },
          ),
      ],
    );
  }
}
