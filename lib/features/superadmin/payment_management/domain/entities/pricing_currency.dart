import 'package:equatable/equatable.dart';

class PricingCurrency extends Equatable {
  final int id;
  final String currencyType;
  final String code;
  final String? symbol;

  const PricingCurrency({
    required this.id,
    required this.currencyType,
    required this.code,
    this.symbol,
  });

  String get displayLabel {
    final sym = (symbol == null || symbol!.isEmpty) ? '' : ' ($symbol)';
    return '$code — $currencyType$sym';
  }

  @override
  List<Object?> get props => [id, currencyType, code, symbol];
}
