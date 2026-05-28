abstract class PublishRequestDetailEvent {}

class PublishRequestDetailInit extends PublishRequestDetailEvent {}

class PublishRequestApprove extends PublishRequestDetailEvent {
  final String? notes;
  final int? firebaseProjectAccountId;

  PublishRequestApprove(this.notes, {this.firebaseProjectAccountId});
}

class PublishRequestReject extends PublishRequestDetailEvent {
  final String? notes;
  PublishRequestReject(this.notes);
}
