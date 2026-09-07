/// Maintainer-recommended adapter purchases.
///
/// Marketplace listings change. This is not a certification or a guarantee
/// that every unit under the URL is the same hardware.
library;

/// Which storefront a listing points at, as an identifier rather than a word.
///
/// It used to be the word — `'蝦皮'` — which the panel then compared with `==`
/// to pick an ARB entry. That is an enum the compiler cannot check and a
/// translation stored in the catalog, and the panel's fallback existed to
/// absorb the case where the two drifted: an unrecognised label was rendered
/// as itself, because sending somebody to the wrong shop is worse than showing
/// the right shop in the wrong script.
///
/// An enum keeps that property and strengthens it. There is no unrecognised
/// case left to fall back from: `recommendedStoreLabel` switches exhaustively,
/// so a second storefront cannot be added here without the compiler asking
/// what it is called in each language. The failure the fallback was protecting
/// against — a store rendered under another store's name — is now unwritable
/// rather than merely unlikely.
enum RecommendedStore { shopee }

/// One storefront entry. Add more stores as entries, do not fork the UI.
class RecommendedPurchase {
  const RecommendedPurchase({
    required this.id,
    required this.store,
    required this.productLabel,
    required this.url,
    required this.model,
    required this.radioApproval,
  });

  final String id;
  final RecommendedStore store;
  final String productLabel;
  final String url;
  final String model;
  final String radioApproval;

  Uri get uri => Uri.parse(url);
}

abstract final class RecommendedPurchases {
  // The disclosure used to be four `const` strings here. Nothing has rendered
  // them since the panel moved onto `recommendedPurchaseDisclosure` and
  // `recommendedPurchaseShortDisclosureLead` in the ARBs; only a test still
  // held them up, which made them look load-bearing while the sentences a
  // reader actually sees went unguarded. A commission disclosure that is dead
  // code is worse than none: it reads like a promise somebody is keeping.
  //
  // The claims they carried are asserted against the shipped copy, in both
  // languages, in test/recommended_purchases_test.dart.

  static const entries = <RecommendedPurchase>[
    RecommendedPurchase(
      id: 'shopee-cl-obdii-m25b',
      store: RecommendedStore.shopee,
      productLabel: 'CARLZS LAB CL-OBDII-M25B',
      url: 'https://s.shopee.tw/3LQPiOY7uv',
      model: 'CL-OBDII-M25B',
      radioApproval: 'CCAH22LP5300T8',
    ),
  ];
}
