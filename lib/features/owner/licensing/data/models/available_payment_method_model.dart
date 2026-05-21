class AvailablePaymentMethodModel {
  final int id;
  final String code;
  final String typeName;
  final String displayName;
  final String providerCode;

  const AvailablePaymentMethodModel({
    required this.id,
    required this.code,
    required this.typeName,
    required this.displayName,
    required this.providerCode,
  });

  factory AvailablePaymentMethodModel.fromJson(Map<String, dynamic> j) =>
      AvailablePaymentMethodModel(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        code: j['code']?.toString() ?? '',
        typeName: j['typeName']?.toString() ?? '',
        displayName: j['displayName']?.toString() ?? '',
        providerCode: j['providerCode']?.toString() ?? '',
      );

  bool get isOnline {
    final c = providerCode.toUpperCase();
    return c.contains('STRIPE') || c.contains('PAYPAL') || c.contains('MPGS');
  }
}
