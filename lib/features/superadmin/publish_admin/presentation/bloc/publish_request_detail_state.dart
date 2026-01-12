import '../../../publish_admin/domain/entities/app_publish_request_admin.dart';

class PublishRequestDetailState {
  final AppPublishRequestAdmin item;
  final bool acting;
  final String? error;
  final String? success;

  const PublishRequestDetailState({
    required this.item,
    required this.acting,
    this.error,
    this.success,
  });

  PublishRequestDetailState copyWith({
    AppPublishRequestAdmin? item,
    bool? acting,
    String? error,
    String? success,
  }) {
    return PublishRequestDetailState(
      item: item ?? this.item,
      acting: acting ?? this.acting,
      error: error,
      success: success,
    );
  }
}
