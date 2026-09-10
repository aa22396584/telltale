/// Language preference control. Self-named options, no flags.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/locale_resolution.dart';
import '../../state/language_switch_guard.dart';
import '../../state/locale_settings.dart';

/// The options, each written in its own language.
///
/// These deliberately do NOT go through [AppLocalizations], and this is the one
/// place in the app where a hard-coded language name is correct. Somebody
/// reaching this screen is usually here because the app is in a language they
/// cannot read; a picker that renders "英文 / 繁體中文" to them, or
/// "English / Traditional Chinese" to a reader of Chinese, hides the very row
/// they came to find. A self-name is legible to the person who needs it no
/// matter which language is currently on screen, which is why the system
/// option is bilingual rather than translated.
///
/// So this function takes no [AppLocalizations]: an unused parameter would
/// imply the strings are a translation gap somebody should close.
String localePreferenceLabel(LocalePreference preference) {
  return switch (preference) {
    LocalePreference.english => 'English',
    LocalePreference.traditionalChinese => '繁體中文',
    LocalePreference.german => 'Deutsch',
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
              if (value == current) return;
              final block = ref.read(languageSwitchBlockProvider);
              if (block != LanguageSwitchBlock.none) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(languageSwitchBlockText(l10n, block)),
                  ),
                );
                return;
              }
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
