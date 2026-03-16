import '../../domain/entities/ios_internal_testing_app_summary.dart';
import 'ios_internal_testing_request_model.dart';

class IosInternalTestingAppSummaryModel {
  final List<IosInternalTestingRequestModel> requests;
  final int usedSlots;
  final int maxSlots;

  IosInternalTestingAppSummaryModel({
    required this.requests,
    required this.usedSlots,
    required this.maxSlots,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory IosInternalTestingAppSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['requests'];
    final list = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(IosInternalTestingRequestModel.fromJson)
            .toList()
        : <IosInternalTestingRequestModel>[];

    return IosInternalTestingAppSummaryModel(
      requests: list,
      usedSlots: _asInt(json['usedSlots']),
      maxSlots: _asInt(json['maxSlots']),
    );
  }

  IosInternalTestingAppSummary toEntity() {
    return IosInternalTestingAppSummary(
      requests: requests.map((e) => e.toEntity()).toList(),
      usedSlots: usedSlots,
      maxSlots: maxSlots,
    );
  }
}