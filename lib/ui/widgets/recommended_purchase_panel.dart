/// Affiliate purchase panel for the maintainer-recommended adapter.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/affiliate/recommended_purchases.dart';
import '../../core/theme/app_theme.dart';
import 'panel.dart';

typedef OpenRecommendedPurchase = Future<bool> Function(Uri uri);

Future<void> _openPurchase(
  BuildContext context, {
  required RecommendedPurchase purchase,
  required OpenRecommendedPurchase? onOpen,
}) async {
  final opener = onOpen ?? _launchExternal;
  var ok = false;
  try {
    ok = await opener(purchase.uri);
  } on Object {
    ok = false;
  }
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('無法開啟${purchase.storeLabel}連結')));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('推薦轉接器'),
        for (final purchase in RecommendedPurchases.entries) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase.productLabel, style: context.texts.titleSmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  '型號 ${purchase.model} · NCC ${purchase.radioApproval}',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  RecommendedPurchases.disclosure,
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
                    label: Text('在${purchase.storeLabel}查看'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final purchase in RecommendedPurchases.entries)
          TextButton(
            key: Key('recommended_purchase_link_${purchase.id}'),
            onPressed: () =>
                _openPurchase(context, purchase: purchase, onOpen: onOpen),
            child: Text('還沒有轉接器？在${purchase.storeLabel}看推薦款'),
          ),
        Text(
          RecommendedPurchases.shortDisclosureLead,
          style: context.texts.bodySmall,
        ),
        TextButton(
          key: const Key('recommended_purchase_open_settings'),
          onPressed: onOpenDisclosure,
          child: const Text(RecommendedPurchases.shortDisclosureAction),
        ),
      ],
    );
  }
}
