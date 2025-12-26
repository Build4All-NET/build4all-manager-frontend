class CurrencyModel {
  final int id;
  final String currencyType;
  final String code;
  final String symbol;

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

  String get label => '$code ($symbol) • $currencyType';
}
