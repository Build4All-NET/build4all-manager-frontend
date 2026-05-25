import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import '../../data/models/social_channel.dart';
import '../../data/models/social_post.dart';
import '../../data/services/social_api.dart';
import 'item_social_state.dart';

/// Owns the data for one product's social panel: the tenant's active
/// feed-capable channels, per-channel overrides, and the most recent posts
/// for the item.
class ItemSocialCubit extends Cubit<ItemSocialState> {
  final SocialApi _api;
  final int itemId;

  ItemSocialCubit({required this.itemId, SocialApi? api})
      : _api = api ?? SocialApi(),
        super(const ItemSocialState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    try {
      final results = await Future.wait([
        _api.listChannels(),
        _api.listOverrides(itemId),
        _api.listItemPosts(itemId),
      ]);
      final channels = (results[0] as List<SocialChannel>)
          .where((c) => c.provider != SocialChannelProvider.metaCatalog &&
                        c.provider != SocialChannelProvider.whatsappCatalog)
          .toList(growable: false);
      final overrides = {
        for (final o in results[1] as List<SocialItemOverride>) o.channelId: o,
      };
      emit(state.copyWith(
        loading: false,
        channels: channels,
        overridesByChannelId: overrides,
        recentPosts: results[2] as List<SocialPost>,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> setAutoPublishOverride(int channelId, bool? value) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      // null means "inherit" → delete the override row entirely; explicit
      // true/false → upsert.
      if (value == null) {
        if (state.overridesByChannelId.containsKey(channelId)) {
          await _api.deleteOverride(itemId, channelId);
        }
        final next = Map<int, SocialItemOverride>.of(state.overridesByChannelId)
          ..remove(channelId);
        emit(state.copyWith(mutating: false, overridesByChannelId: next));
        return;
      }
      final existingCaption = state.overridesByChannelId[channelId]?.captionOverride;
      final upd = await _api.putOverride(itemId, channelId,
          autoPublishOverride: value, captionOverride: existingCaption);
      final next = Map<int, SocialItemOverride>.of(state.overridesByChannelId);
      next[channelId] = upd;
      emit(state.copyWith(mutating: false, overridesByChannelId: next));
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> setCaptionOverride(int channelId, String? captionOverride) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final existingAuto = state.overridesByChannelId[channelId]?.autoPublishOverride;
      final upd = await _api.putOverride(itemId, channelId,
          autoPublishOverride: existingAuto, captionOverride: captionOverride);
      final next = Map<int, SocialItemOverride>.of(state.overridesByChannelId);
      next[channelId] = upd;
      emit(state.copyWith(mutating: false, overridesByChannelId: next));
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> publishNow(int channelId) async {
    emit(state.copyWith(mutating: true, clearError: true, clearInfo: true));
    try {
      final post = await _api.publishNow(itemId, channelId);
      // Prepend the new post so the user sees feedback immediately. The
      // dispatcher will move it through PENDING → RUNNING → SUCCEEDED on
      // its next tick (≤5s by default).
      final next = [post, ...state.recentPosts];
      emit(state.copyWith(
        mutating: false,
        recentPosts: next,
        infoMessage: 'Queued for ${post.channelName}',
      ));
    } catch (e) {
      emit(state.copyWith(mutating: false, error: ApiErrorHandler.message(e)));
    }
  }

  void clearMessage() => emit(state.copyWith(clearError: true, clearInfo: true));
}
