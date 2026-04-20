import '../../domain/entities/managed_payment_type.dart';

class ManagedPaymentTypeModel extends ManagedPaymentType {
  const ManagedPaymentTypeModel({
    required super.id,
    required super.typeName,
    required super.code,
    super.description = '',
    required super.isActive,
    super.createdAt,
  });

  factory ManagedPaymentTypeModel.fromJson(Map<String, dynamic> j) =>
      ManagedPaymentTypeModel(
        id: (j['id'] ?? 0) as int,
        typeName: (j['typeName'] ?? j['name'] ?? '').toString(),
        code: (j['code'] ?? '').toString().toUpperCase(),
        description: (j['description'] ?? '').toString(),
        isActive: (j['isActive'] ?? j['active'] ?? true) as bool,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );

  factory ManagedPaymentTypeModel.fromEntity(ManagedPaymentType e) =>
      ManagedPaymentTypeModel(
        id: e.id,
        typeName: e.typeName,
        code: e.code,
        description: e.description,
        isActive: e.isActive,
        createdAt: e.createdAt,
      );

  // Includes code — used only on POST (create).
  Map<String, dynamic> toCreateBody() => {
        'typeName': typeName,
        'code': code.toUpperCase(),
        'description': description,
        'isActive': isActive,
      };

  // Excludes code — immutable after creation.
  Map<String, dynamic> toUpdateBody() => {
        'typeName': typeName,
        'description': description,
        'isActive': isActive,
      };
}
