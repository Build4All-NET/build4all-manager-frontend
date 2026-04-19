import 'package:equatable/equatable.dart';

class ManagedPaymentType extends Equatable {
  final int id;
  final String typeName;
  final String code;
  final String description;
  final bool isActive;
  final DateTime? createdAt;

  const ManagedPaymentType({
    required this.id,
    required this.typeName,
    required this.code,
    this.description = '',
    required this.isActive,
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, typeName, code, description, isActive, createdAt];
}
