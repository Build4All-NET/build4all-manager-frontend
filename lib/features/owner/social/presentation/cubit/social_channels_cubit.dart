import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import '../../data/models/social_channel.dart';
import '../../data/services/social_api.dart';
import 'social_channels_state.dart';

/// State container for the channels list screen. Owns the API client and the
/// list of currently-known channels; the channel-detail screen takes a single
/// channel as input and patches via this cubit so the list stays consistent.
class SocialChannelsCubit extends Cubit<SocialChannelsState> {
  final SocialApi _api;

  SocialChannelsCubit({SocialApi? api})
      : _api = api ?? SocialApi(),
        super(const SocialChannelsState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    try {
      final list = await _api.listChannels();
      emit(state.copyWith(loading: false, channels: list));
    } catch (e) {
      emit(state.copyWith(loading: false, error: ApiErrorHandler.message(e)));
    }
  }

  /// Replace one channel in the list (after PATCH or after callback returns).
  void _upsertLocal(SocialChannel updated) {
    final next = List<SocialChannel>.of(state.channels);
    final i = next.indexWhere((c) => c.id == updated.id);
    if (i >= 0) {
      next[i] = updated;
    } else {
      next.insert(0, updated);
    }
    emit(state.copyWith(channels: next, mutating: false));
  }

  Future<void> setAutoPublish(SocialChannel ch, bool enabled) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final out = await _api.updateChannel(ch.id, autoPublishEnabled: enabled);
      _upsertLocal(out);
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> setCaptionTemplate(SocialChannel ch, String template) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final out = await _api.updateChannel(ch.id, captionTemplate: template);
      _upsertLocal(out);
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> setStatus(SocialChannel ch, SocialChannelStatus status) async {
    if (!status.userSettable) {
      emit(state.copyWith(error: 'Status ${status.wire} cannot be set by the user'));
      return;
    }
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final out = await _api.updateChannel(ch.id, status: status);
      _upsertLocal(out);
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> disconnect(SocialChannel ch) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      await _api.deleteChannel(ch.id);
      final next = state.channels.where((c) => c.id != ch.id).toList();
      emit(state.copyWith(mutating: false, channels: next,
          infoMessage: 'Disconnected ${ch.externalAccountName ?? ch.externalAccountId}'));
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  /// After the WebView returns code+state, complete the OAuth and merge the
  /// newly connected channel(s) into the list.
  Future<void> completeOAuth({required String code, required String state}) async {
    emit(this.state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final newOnes = await _api.completeOAuth(code: code, state: state);
      for (final ch in newOnes) {
        _upsertLocal(ch);
      }
      emit(this.state.copyWith(
        mutating: false,
        infoMessage: newOnes.length == 1
            ? 'Connected ${newOnes.first.externalAccountName ?? newOnes.first.externalAccountId}'
            : 'Connected ${newOnes.length} channels',
      ));
    } catch (e) {
      emit(this.state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<OAuthStart> beginOAuth(SocialChannelProvider provider,
      {required String redirectUri}) {
    return _api.startOAuth(provider, redirectUri: redirectUri);
  }

  void clearMessage() => emit(state.copyWith(clearError: true, clearInfo: true));
}
