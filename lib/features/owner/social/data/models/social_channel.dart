/// Mirror of the backend's `SocialChannelDto`.
///
/// Never carries an access/refresh token — the backend strips them. The only
/// diagnostic field is [tokenSuffix] (last 4 chars of the decrypted token).
enum SocialChannelProvider {
  facebookPage,
  instagram,
  metaCatalog,
  whatsappCatalog;

  static SocialChannelProvider fromWire(String raw) {
    switch (raw) {
      case 'FACEBOOK_PAGE':    return SocialChannelProvider.facebookPage;
      case 'INSTAGRAM':        return SocialChannelProvider.instagram;
      case 'META_CATALOG':     return SocialChannelProvider.metaCatalog;
      case 'WHATSAPP_CATALOG': return SocialChannelProvider.whatsappCatalog;
    }
    throw ArgumentError('Unknown SocialChannelProvider wire value: $raw');
  }

  String get wire {
    switch (this) {
      case SocialChannelProvider.facebookPage:    return 'FACEBOOK_PAGE';
      case SocialChannelProvider.instagram:       return 'INSTAGRAM';
      case SocialChannelProvider.metaCatalog:     return 'META_CATALOG';
      case SocialChannelProvider.whatsappCatalog: return 'WHATSAPP_CATALOG';
    }
  }

  String get displayName {
    switch (this) {
      case SocialChannelProvider.facebookPage:    return 'Facebook Page';
      case SocialChannelProvider.instagram:       return 'Instagram';
      case SocialChannelProvider.metaCatalog:     return 'Meta Commerce Catalog';
      case SocialChannelProvider.whatsappCatalog: return 'WhatsApp Catalog';
    }
  }
}

enum SocialChannelStatus {
  active,
  disabled,
  tokenExpired,
  revoked,
  error;

  static SocialChannelStatus fromWire(String raw) {
    switch (raw) {
      case 'ACTIVE':        return SocialChannelStatus.active;
      case 'DISABLED':      return SocialChannelStatus.disabled;
      case 'TOKEN_EXPIRED': return SocialChannelStatus.tokenExpired;
      case 'REVOKED':       return SocialChannelStatus.revoked;
      case 'ERROR':         return SocialChannelStatus.error;
    }
    throw ArgumentError('Unknown SocialChannelStatus wire value: $raw');
  }

  String get wire {
    switch (this) {
      case SocialChannelStatus.active:       return 'ACTIVE';
      case SocialChannelStatus.disabled:     return 'DISABLED';
      case SocialChannelStatus.tokenExpired: return 'TOKEN_EXPIRED';
      case SocialChannelStatus.revoked:      return 'REVOKED';
      case SocialChannelStatus.error:        return 'ERROR';
    }
  }

  /// Whether the OWNER can flip into this status. The remaining values are
  /// system-managed (set by the backend on token refresh / publish failures)
  /// and the PATCH endpoint rejects them.
  bool get userSettable =>
      this == SocialChannelStatus.active || this == SocialChannelStatus.disabled;
}

class SocialChannel {
  final int id;
  final SocialChannelProvider provider;
  final SocialChannelStatus status;
  final String externalAccountId;
  final String? externalAccountName;
  final bool autoPublishEnabled;
  final String? captionTemplate;
  final DateTime? tokenExpiresAt;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? tokenSuffix;

  const SocialChannel({
    required this.id,
    required this.provider,
    required this.status,
    required this.externalAccountId,
    required this.autoPublishEnabled,
    this.externalAccountName,
    this.captionTemplate,
    this.tokenExpiresAt,
    this.lastSyncedAt,
    this.lastError,
    this.createdAt,
    this.updatedAt,
    this.tokenSuffix,
  });

  factory SocialChannel.fromJson(Map<String, dynamic> j) {
    DateTime? p(Object? v) =>
        (v == null || v.toString().isEmpty) ? null : DateTime.tryParse(v.toString());
    return SocialChannel(
      id: (j['id'] as num).toInt(),
      provider: SocialChannelProvider.fromWire(j['provider'] as String),
      status: SocialChannelStatus.fromWire(j['status'] as String),
      externalAccountId: (j['externalAccountId'] ?? '').toString(),
      externalAccountName: j['externalAccountName']?.toString(),
      autoPublishEnabled: j['autoPublishEnabled'] == true,
      captionTemplate: j['captionTemplate']?.toString(),
      tokenExpiresAt: p(j['tokenExpiresAt']),
      lastSyncedAt:   p(j['lastSyncedAt']),
      lastError: j['lastError']?.toString(),
      createdAt: p(j['createdAt']),
      updatedAt: p(j['updatedAt']),
      tokenSuffix: j['tokenSuffix']?.toString(),
    );
  }
}
