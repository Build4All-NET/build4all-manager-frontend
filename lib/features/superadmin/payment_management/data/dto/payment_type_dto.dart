class CreatePaymentTypeDto {
  final String typeName;
  final String code;
  final String description;
  final bool isActive;

  const CreatePaymentTypeDto({
    required this.typeName,
    required this.code,
    this.description = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'typeName': typeName,
        'code': code.toUpperCase(),
        'description': description,
        'isActive': isActive,
      };
}

class UpdatePaymentTypeDto {
  final String typeName;
  final String description;
  final bool isActive;

  const UpdatePaymentTypeDto({
    required this.typeName,
    this.description = '',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'typeName': typeName,
        'description': description,
        'isActive': isActive,
      };
}

class TogglePaymentTypeDto {
  final bool isActive;
  const TogglePaymentTypeDto({required this.isActive});
  Map<String, dynamic> toJson() => {'isActive': isActive};
}

class PaymentTypeResponseDto {
  final int id;
  final String typeName;
  final String code;
  final String description;
  final bool isActive;
  final String? createdAt;

  const PaymentTypeResponseDto({
    required this.id,
    required this.typeName,
    required this.code,
    this.description = '',
    required this.isActive,
    this.createdAt,
  });

  factory PaymentTypeResponseDto.fromJson(Map<String, dynamic> j) =>
      PaymentTypeResponseDto(
        id: (j['id'] ?? 0) as int,
        typeName: (j['typeName'] ?? j['name'] ?? '').toString(),
        code: (j['code'] ?? '').toString().toUpperCase(),
        description: (j['description'] ?? '').toString(),
        isActive: (j['isActive'] ?? j['active'] ?? true) as bool,
        createdAt: j['createdAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeName': typeName,
        'code': code,
        'description': description,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
