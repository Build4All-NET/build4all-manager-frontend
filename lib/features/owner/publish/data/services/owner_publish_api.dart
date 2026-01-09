import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/publish_draft.dart';

class OwnerPublishApi {
  final Dio dio;
  OwnerPublishApi(this.dio);

  Future<PublishDraft> getOrCreateDraft({
    required int aupId,
    required PublishPlatform platform,
    required PublishStore store,
  }) async {
    final r = await dio.post(
      '/owner/publish/draft',
      data: {
        'aupId': aupId,
        'platform': platformToApi(platform),
        'store': storeToApi(store),
      },
    );

    final data = (r.data as Map)['data'] as Map<String, dynamic>;
    return PublishDraft.fromJson(data);
  }

  /// Patch draft fields (text fields + optional URLs if backend supports it)
  Future<PublishDraft> patchDraft({
    required int requestId,
    String? applicationName,
    String? shortDescription,
    String? fullDescription,
    String? category,
    String? countryAvailability,
    PricingType? pricing,
    bool? contentRatingConfirmed,

    // ✅ Add these to support backend returning/storing URLs
    String? appIconUrl,
    List<String>? screenshotsUrls,
  }) async {
    final body = <String, dynamic>{};

    if (applicationName != null) body['applicationName'] = applicationName;
    if (shortDescription != null) body['shortDescription'] = shortDescription;
    if (fullDescription != null) body['fullDescription'] = fullDescription;

    if (category != null) body['category'] = category;
    if (countryAvailability != null)
      body['countryAvailability'] = countryAvailability;
    if (pricing != null) body['pricing'] = pricingToApi(pricing);
    if (contentRatingConfirmed != null)
      body['contentRatingConfirmed'] = contentRatingConfirmed;

    // ✅ Optional URL patch (if backend expects them)
    if (appIconUrl != null) body['appIconUrl'] = appIconUrl;
    if (screenshotsUrls != null) body['screenshotsUrls'] = screenshotsUrls;

    final r = await dio.patch('/owner/publish/$requestId', data: body);
    final data = (r.data as Map)['data'] as Map<String, dynamic>;
    return PublishDraft.fromJson(data);
  }

  /// Upload icon + screenshots as FILES (multipart/form-data)
  /// Backend:
  /// POST /api/owner/publish/{requestId}/assets
  /// Parts:
  /// - appIcon: MultipartFile? (optional)
  /// - screenshots: MultipartFile[]? (optional)
  Future<PublishDraft> uploadAssets({
    required int requestId,
    File? appIcon,
    List<File>? screenshots,
  }) async {
    final form = FormData();

    if (appIcon != null) {
      form.files.add(
        MapEntry(
          'appIcon',
          await MultipartFile.fromFile(
            appIcon.path,
            filename: appIcon.path.split('/').last,
          ),
        ),
      );
    }

    if (screenshots != null && screenshots.isNotEmpty) {
      for (final f in screenshots) {
        form.files.add(
          MapEntry(
            'screenshots',
            await MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
          ),
        );
      }
    }

    final r = await dio.post(
      '/owner/publish/$requestId/assets',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = (r.data as Map)['data'] as Map<String, dynamic>;
    return PublishDraft.fromJson(data);
  }

  Future<PublishDraft> submit({required int requestId}) async {
    final r = await dio.post('/owner/publish/$requestId/submit');
    final data = (r.data as Map)['data'] as Map<String, dynamic>;
    return PublishDraft.fromJson(data);
  }
}
