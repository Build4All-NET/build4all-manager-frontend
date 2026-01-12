abstract class PublishRequestDetailEvent {}

class PublishRequestDetailInit extends PublishRequestDetailEvent {}

class PublishRequestApprove extends PublishRequestDetailEvent {
  final String? notes;
  PublishRequestApprove(this.notes);
}

class PublishRequestReject extends PublishRequestDetailEvent {
  final String? notes;
  PublishRequestReject(this.notes);
}
