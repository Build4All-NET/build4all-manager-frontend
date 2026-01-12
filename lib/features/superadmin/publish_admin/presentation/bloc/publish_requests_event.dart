abstract class PublishRequestsEvent {}

class PublishRequestsLoad extends PublishRequestsEvent {
  final String status;
  PublishRequestsLoad(this.status);
}

class PublishRequestsSearchChanged extends PublishRequestsEvent {
  final String query;
  PublishRequestsSearchChanged(this.query);
}

class PublishRequestsRefresh extends PublishRequestsEvent {}
