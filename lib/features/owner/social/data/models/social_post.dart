// Mirror of the backend's SocialPostDto. Never carries an access token —
// the channel is referenced by id + name only.

enum SocialPostStatus {
  pending, running, succeeded, failed, skipped, cancelled;

  static SocialPostStatus fromWire(String raw) {
    switch (raw) {
      case 'PENDING':   return SocialPostStatus.pending;
      case 'RUNNING':   return SocialPostStatus.running;
      case 'SUCCEEDED': return SocialPostStatus.succeeded;
      case 'FAILED':    return SocialPostStatus.failed;
      case 'SKIPPED':   return SocialPostStatus.skipped;
      case 'CANCELLED': return SocialPostStatus.cancelled;
    }
    throw ArgumentError('Unknown SocialPostStatus wire value: $raw');
  }

  bool get isTerminal =>
      this == SocialPostStatus.succeeded ||
      this == SocialPostStatus.failed ||
      this == SocialPostStatus.skipped ||
      this == SocialPostStatus.cancelled;
}

enum SocialPostAction {
  postFeed, postReel, postStory, catalogUpsert, catalogDelete;

  static SocialPostAction fromWire(String raw) {
    switch (raw) {
      case 'POST_FEED':       return SocialPostAction.postFeed;
      case 'POST_REEL':       return SocialPostAction.postReel;
      case 'POST_STORY':      return SocialPostAction.postStory;
      case 'CATALOG_UPSERT':  return SocialPostAction.catalogUpsert;
      case 'CATALOG_DELETE':  return SocialPostAction.catalogDelete;
    }
    throw ArgumentError('Unknown SocialPostAction wire value: $raw');
  }
}

enum FailureClass {
  transient_, permanent;
  static FailureClass? fromWire(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'TRANSIENT': return FailureClass.transient_;
      case 'PERMANENT': return FailureClass.permanent;
    }
    return null;
  }
}

class SocialPost {
  final int id;
  final int channelId;
  final String channelName;
  final int? itemId;
  final SocialPostAction action;
  final SocialPostStatus status;
  final int attemptCount;
  final int maxAttempts;
  final DateTime? nextAttemptAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? externalPostId;
  final String? externalPermalink;
  final String? errorCode;
  final String? errorMessage;
  final FailureClass? failureClass;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialPost({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.action,
    required this.status,
    required this.attemptCount,
    required this.maxAttempts,
    this.itemId,
    this.nextAttemptAt,
    this.startedAt,
    this.finishedAt,
    this.externalPostId,
    this.externalPermalink,
    this.errorCode,
    this.errorMessage,
    this.failureClass,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> j) {
    DateTime? p(Object? v) =>
        (v == null || v.toString().isEmpty) ? null : DateTime.tryParse(v.toString());
    return SocialPost(
      id: (j['id'] as num).toInt(),
      channelId: (j['channelId'] as num).toInt(),
      channelName: (j['channelName'] ?? '').toString(),
      itemId: (j['itemId'] as num?)?.toInt(),
      action: SocialPostAction.fromWire(j['action'] as String),
      status: SocialPostStatus.fromWire(j['status'] as String),
      attemptCount: (j['attemptCount'] as num?)?.toInt() ?? 0,
      maxAttempts:  (j['maxAttempts']  as num?)?.toInt() ?? 5,
      nextAttemptAt: p(j['nextAttemptAt']),
      startedAt:     p(j['startedAt']),
      finishedAt:    p(j['finishedAt']),
      externalPostId:    j['externalPostId']?.toString(),
      externalPermalink: j['externalPermalink']?.toString(),
      errorCode:    j['errorCode']?.toString(),
      errorMessage: j['errorMessage']?.toString(),
      failureClass: FailureClass.fromWire(j['failureClass']?.toString()),
      createdAt: p(j['createdAt']),
      updatedAt: p(j['updatedAt']),
    );
  }
}

/// Per-item per-channel override (3-valued autoPublish + optional caption).
class SocialItemOverride {
  final int id;
  final int itemId;
  final int channelId;
  /// null = inherit channel default; true/false = explicit.
  final bool? autoPublishOverride;
  final String? captionOverride;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialItemOverride({
    required this.id,
    required this.itemId,
    required this.channelId,
    this.autoPublishOverride,
    this.captionOverride,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialItemOverride.fromJson(Map<String, dynamic> j) {
    DateTime? p(Object? v) =>
        (v == null || v.toString().isEmpty) ? null : DateTime.tryParse(v.toString());
    return SocialItemOverride(
      id: (j['id'] as num).toInt(),
      itemId: (j['itemId'] as num).toInt(),
      channelId: (j['channelId'] as num).toInt(),
      autoPublishOverride: j['autoPublishOverride'] as bool?,
      captionOverride: j['captionOverride']?.toString(),
      createdAt: p(j['createdAt']),
      updatedAt: p(j['updatedAt']),
    );
  }
}
