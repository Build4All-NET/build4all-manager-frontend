import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/firebase_pool_remote_ds.dart';
import 'firebase_pool_event.dart';
import 'firebase_pool_state.dart';

class FirebasePoolBloc extends Bloc<FirebasePoolEvent, FirebasePoolState> {
  final FirebasePoolRemoteDs _ds;

  FirebasePoolBloc({FirebasePoolRemoteDs? ds})
      : _ds = ds ?? FirebasePoolRemoteDs(),
        super(const FirebasePoolState()) {
    on<LoadFirebasePool>(_onLoad);
    on<RefreshFirebasePool>(_onLoad);
    on<EnableFirebaseAccount>(_onEnable);
    on<DisableFirebaseAccount>(_onDisable);
    on<SetDefaultFirebaseAccount>(_onSetDefault);
    on<SaveFirebaseAccount>(_onSave);
  }

  Future<void> _onLoad(
      FirebasePoolEvent e, Emitter<FirebasePoolState> emit) async {
    emit(state.copyWith(
        loading: true, clearError: true, clearSuccess: true));
    try {
      final models = await _ds.getAll();
      emit(state.copyWith(
        loading: false,
        items: models.map((m) => m.toEntity()).toList(),
      ));
    } catch (err) {
      emit(state.copyWith(
          loading: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _onEnable(
      EnableFirebaseAccount e, Emitter<FirebasePoolState> emit) async {
    emit(state.copyWith(
        actingIds: {...state.actingIds, e.id},
        clearError: true,
        clearSuccess: true));
    try {
      await _ds.enable(e.id);
      final models = await _ds.getAll();
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
        actingIds: ids,
        items: models.map((m) => m.toEntity()).toList(),
        success: 'Account enabled',
      ));
    } catch (err) {
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
          actingIds: ids, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _onDisable(
      DisableFirebaseAccount e, Emitter<FirebasePoolState> emit) async {
    emit(state.copyWith(
        actingIds: {...state.actingIds, e.id},
        clearError: true,
        clearSuccess: true));
    try {
      await _ds.disable(e.id);
      final models = await _ds.getAll();
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
        actingIds: ids,
        items: models.map((m) => m.toEntity()).toList(),
        success: 'Account disabled',
      ));
    } catch (err) {
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
          actingIds: ids, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _onSetDefault(
      SetDefaultFirebaseAccount e, Emitter<FirebasePoolState> emit) async {
    emit(state.copyWith(
        actingIds: {...state.actingIds, e.id},
        clearError: true,
        clearSuccess: true));
    try {
      await _ds.setDefault(e.id);
      final models = await _ds.getAll();
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
        actingIds: ids,
        items: models.map((m) => m.toEntity()).toList(),
        success: 'Default account updated',
      ));
    } catch (err) {
      final ids = {...state.actingIds}..remove(e.id);
      emit(state.copyWith(
          actingIds: ids, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _onSave(
      SaveFirebaseAccount e, Emitter<FirebasePoolState> emit) async {
    final actingIds =
        e.id != null ? <int>{...state.actingIds, e.id!} : state.actingIds;
    emit(state.copyWith(
        loading: true,
        actingIds: actingIds,
        clearError: true,
        clearSuccess: true));
    try {
      if (e.id == null) {
        await _ds.create(
          firebaseProjectId: e.firebaseProjectId,
          displayName: e.displayName,
          serviceAccountCredentialsJson: e.serviceAccountCredentialsJson,
          priority: e.priority,
          maxAndroidApps: e.maxAndroidApps,
          maxIosApps: e.maxIosApps,
          isDefault: e.isDefault,
        );
      } else {
        await _ds.update(
          e.id!,
          displayName: e.displayName,
          serviceAccountCredentialsJson:
              e.serviceAccountCredentialsJson.trim().isNotEmpty
                  ? e.serviceAccountCredentialsJson
                  : null,
          priority: e.priority,
          maxAndroidApps: e.maxAndroidApps,
          maxIosApps: e.maxIosApps,
          isDefault: e.isDefault,
        );
      }
      final models = await _ds.getAll();
      final newIds =
          e.id != null ? ({...state.actingIds}..remove(e.id!)) : <int>{};
      emit(state.copyWith(
        loading: false,
        actingIds: newIds,
        items: models.map((m) => m.toEntity()).toList(),
        success: e.id == null ? 'Account created' : 'Account updated',
      ));
    } catch (err) {
      final newIds =
          e.id != null ? ({...state.actingIds}..remove(e.id!)) : <int>{};
      emit(state.copyWith(
        loading: false,
        actingIds: newIds,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}
