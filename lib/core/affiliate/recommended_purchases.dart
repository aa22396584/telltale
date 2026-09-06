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
  static const disclosure =
      '這是維護者的推廣分潤連結；符合條件的購買可能產生佣金。'
      '不是轉接器認證或購買保證。賣場內容與硬體版本可能變更，'
      '購買前請核對完整型號與 NCC 號碼。你也可以自行搜尋其他通路。';

  /// Connect keeps the catalog off the primary actions; Settings has [disclosure].
  static const shortDisclosure = '這是推廣分潤連結，不是轉接器認證。完整說明在設定。';

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
