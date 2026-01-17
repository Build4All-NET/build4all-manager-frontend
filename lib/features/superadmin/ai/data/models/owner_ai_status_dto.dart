import '../../domain/entities/owner_ai_status.dart';

class OwnerAiStatusDto {
  final int ownerId;
  final bool aiEnabled;

  const OwnerAiStatusDto({
    required this.ownerId,
    required this.aiEnabled,
  });

  factory OwnerAiStatusDto.fromJson(Map<String, dynamic> json) {
    return OwnerAiStatusDto(
      ownerId: (json['ownerId'] as num?)?.toInt() ?? 0,
      aiEnabled: json['aiEnabled'] == true,
    );
  }

  OwnerAiStatus toEntity() => OwnerAiStatus(
        ownerId: ownerId,
        aiEnabled: aiEnabled,
      );
}
