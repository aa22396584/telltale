/// Names and descriptions for the gauge skins.
///
/// The skin definitions live in `lib/core/theme/gauge_skin.dart`, which is a
/// `ThemeExtension` built from `const` values and read by the painters. It
/// carries the geometry — angles, tick style, pointer, timing — and nothing a
/// reader sees, so its `id` is the identifier and the words come from here.
///
/// Takes an [AppLocalizations] rather than a [BuildContext] for the same reason
/// the rest of this app does: the caller may be a static helper, and a plain
/// parameter keeps it testable without a widget pump.
library;

import '../../../core/theme/gauge_skin.dart';
import '../../../l10n/generated/app_localizations.dart';

String gaugeSkinName(AppLocalizations l10n, GaugeSkin skin) =>
    switch (skin.id) {
      'cluster' => l10n.gaugeSkinCluster,
      'minimal' => l10n.gaugeSkinMinimal,
      'track' => l10n.gaugeSkinTrack,
      'classic' => l10n.gaugeSkinClassic,
      'night' => l10n.gaugeSkinNight,
      // A skin the app does not know is shown by its id rather than by a
      // guessed name. An id is at least true.
      _ => skin.id,
    };

String gaugeSkinDescription(AppLocalizations l10n, GaugeSkin skin) =>
    switch (skin.id) {
      'cluster' => l10n.gaugeSkinClusterDescription,
      'minimal' => l10n.gaugeSkinMinimalDescription,
      'track' => l10n.gaugeSkinTrackDescription,
      'classic' => l10n.gaugeSkinClassicDescription,
      'night' => l10n.gaugeSkinNightDescription,
      _ => '',
    };
