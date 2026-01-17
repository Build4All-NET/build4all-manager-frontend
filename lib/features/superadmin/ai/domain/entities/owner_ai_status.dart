class OwnerAiStatus {
  final int ownerId;
  final bool aiEnabled;

  const OwnerAiStatus({
    required this.ownerId,
    required this.aiEnabled,
  });

  OwnerAiStatus copyWith({bool? aiEnabled}) {
    return OwnerAiStatus(
      ownerId: ownerId,
      aiEnabled: aiEnabled ?? this.aiEnabled,
    );
  }
}
