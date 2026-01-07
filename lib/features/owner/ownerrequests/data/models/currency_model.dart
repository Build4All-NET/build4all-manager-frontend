class CurrencyModel {
  final int id;
  final String currencyType; // e.g. "US Dollar"
  final String code; // e.g. "USD"
  final String symbol; // e.g. "$"

  CurrencyModel({
    required this.id,
    required this.currencyType,
    required this.code,
    required this.symbol,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: (json['id'] as num).toInt(),
      currencyType: (json['currencyType'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
    );
  }

  /// ✅ What you want to show in dropdown/list: "USD ($)"
  String get shortLabel => '$code ($symbol)';

  /// Optional: full label for search or debug: "USD ($) • US Dollar"
  String get fullLabel => '$code ($symbol) • $currencyType';

  /// Keep compatibility if other screens use `label`
  /// (make `label` short so UI becomes clean everywhere)
  String get label => shortLabel;
}
