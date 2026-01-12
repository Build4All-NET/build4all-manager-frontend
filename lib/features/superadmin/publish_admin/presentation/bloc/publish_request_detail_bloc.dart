import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/approve_request.dart';
import '../../domain/usecases/reject_request.dart';
import '../../../publish_admin/domain/entities/app_publish_request_admin.dart';
import 'publish_request_detail_event.dart';
import 'publish_request_detail_state.dart';

class PublishRequestDetailBloc
    extends Bloc<PublishRequestDetailEvent, PublishRequestDetailState> {
  final ApproveRequest approve;
  final RejectRequest reject;

  PublishRequestDetailBloc({
    required AppPublishRequestAdmin item,
    required this.approve,
    required this.reject,
  }) : super(PublishRequestDetailState(item: item, acting: false)) {
    on<PublishRequestApprove>(_onApprove);
    on<PublishRequestReject>(_onReject);
  }

  Future<void> _onApprove(
      PublishRequestApprove e, Emitter<PublishRequestDetailState> emit) async {
    emit(state.copyWith(acting: true, error: null, success: null));
    try {
      await approve(requestId: state.item.id, notes: e.notes);
      emit(state.copyWith(acting: false, success: 'approved'));
    } catch (err) {
      emit(state.copyWith(acting: false, error: err.toString()));
    }
  }

  Future<void> _onReject(
      PublishRequestReject e, Emitter<PublishRequestDetailState> emit) async {
    emit(state.copyWith(acting: true, error: null, success: null));
    try {
      await reject(requestId: state.item.id, notes: e.notes);
      emit(state.copyWith(acting: false, success: 'rejected'));
    } catch (err) {
      emit(state.copyWith(acting: false, error: err.toString()));
    }
  }
}
