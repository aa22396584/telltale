/// Affiliate purchase panel for the maintainer-recommended adapter.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/affiliate/recommended_purchases.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'panel.dart';

typedef OpenRecommendedPurchase = Future<bool> Function(Uri uri);

/// The storefront's own name, in a script the reader can read.
///
/// The catalog names the store by identifier; the name lives in the ARBs.
/// Shopee publishes as 蝦皮 in Taiwan and as Shopee elsewhere, so both ship,
/// and neither is stored next to the URL where a compiler cannot see it.
///
/// The switch is exhaustive, which is what replaced the fallback this function
/// used to carry. That fallback rendered an unrecognised label as itself,
/// because showing a store's real name in the wrong script is a smaller
/// failure than sending somebody to a store that is not the one named — and
/// with a [RecommendedStore] there is no unrecognised case: a second storefront
/// does not compile until this switch says what it is called.
String recommendedStoreLabel(
  AppLocalizations l10n,
  RecommendedPurchase purchase,
) => switch (purchase.store) {
  RecommendedStore.shopee => l10n.recommendedPurchaseStoreShopee,
};

Future<void> _openPurchase(
  BuildContext context, {
  required RecommendedPurchase purchase,
  required OpenRecommendedPurchase? onOpen,
}) async {
  // Captured before the launch completes: the failure is reported in the
  // language the tap happened in, and nothing reads a context after an await.
  final l10n = AppLocalizations.of(context);
  final opener = onOpen ?? _launchExternal;
  var ok = false;
  try {
    ok = await opener(purchase.uri);
  } on Object {
    ok = false;
  }
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n.recommendedPurchaseOpenFailed(
          recommendedStoreLabel(l10n, purchase),
        ),
      ),
    ),
  );
}

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Full catalog card for Settings: model, NCC, commission disclosure, store CTA.
class RecommendedPurchasePanel extends StatelessWidget {
  const RecommendedPurchasePanel({this.onOpen, super.key});

  /// Tests inject this so a tap does not leave the process.
  final OpenRecommendedPurchase? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(l10n.recommendedPurchaseHeading),
        for (final purchase in RecommendedPurchases.entries) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase.productLabel, style: context.texts.titleSmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.recommendedPurchaseModelLine(
                    purchase.model,
                    purchase.radioApproval,
                  ),
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: Spacing.md),
                // Regulated copy. Every qualifier in it is load-bearing:
                // "may pay", "not an adapter certification", "not a purchase
                // guarantee", and the instruction to check the model and NCC
                // number first. A shorter translation is a weaker disclosure.
                Text(
                  l10n.recommendedPurchaseDisclosure,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: Key('recommended_purchase_${purchase.id}'),
                    onPressed: () => _openPurchase(
                      context,
                      purchase: purchase,
                      onOpen: onOpen,
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(
                      l10n.recommendedPurchaseViewOnStore(
                        recommendedStoreLabel(l10n, purchase),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }
}

/// Secondary Connect footer. Must not compete with 直接連線 / 啟動模擬器 / 上次轉接器.
class RecommendedPurchaseLink extends StatelessWidget {
  const RecommendedPurchaseLink({
    this.onOpen,
    this.onOpenDisclosure,
    super.key,
  });

  /// Tests inject this so a tap does not leave the process.
  final OpenRecommendedPurchase? onOpen;

  /// Connect sends this to Settings. Absent, the action is still shown, inert.
  final VoidCallback? onOpenDisclosure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final purchase in RecommendedPurchases.entries)
          TextButton(
            key: Key('recommended_purchase_link_${purchase.id}'),
            onPressed: () =>
                _openPurchase(context, purchase: purchase, onOpen: onOpen),
            child: Text(
              l10n.recommendedPurchaseNoAdapterYet(
                recommendedStoreLabel(l10n, purchase),
              ),
            ),
          ),
        Text(
          l10n.recommendedPurchaseShortDisclosureLead,
          style: context.texts.bodySmall,
        ),
        TextButton(
          key: const Key('recommended_purchase_open_settings'),
          onPressed: onOpenDisclosure,
          child: Text(l10n.recommendedPurchaseShortDisclosureAction),
        ),
      ],
    );
  }
}
