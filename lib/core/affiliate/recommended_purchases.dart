/// Maintainer-recommended adapter purchases.
///
/// Marketplace listings change. This is not a certification or a guarantee
/// that every unit under the URL is the same hardware.
library;

/// One storefront entry. Add more stores as entries, do not fork the UI.
class RecommendedPurchase {
  const RecommendedPurchase({
    required this.id,
    required this.storeLabel,
    required this.productLabel,
    required this.url,
    required this.model,
    required this.radioApproval,
  });

  final String id;
  final String storeLabel;
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
      storeLabel: '蝦皮',
      productLabel: 'CARLZS LAB CL-OBDII-M25B',
      url: 'https://s.shopee.tw/3LQPiOY7uv',
      model: 'CL-OBDII-M25B',
      radioApproval: 'CCAH22LP5300T8',
    ),
  ];
}
