import 'package:build4all_manager/features/owner/ownerprofile/domain/entities/owner_profile.dart';
import 'package:equatable/equatable.dart';

class OwnerProfileState extends Equatable {
  final bool loading;
  final String? error;
  final OwnerProfile? profile;

  final bool deletingAccount;
  final bool deleteSuccess;
  final String? deleteError;

  const OwnerProfileState({
    required this.loading,
    this.error,
    this.profile,
    required this.deletingAccount,
    required this.deleteSuccess,
    this.deleteError,
  });

  const OwnerProfileState.initial()
      : loading = false,
        error = null,
        profile = null,
        deletingAccount = false,
        deleteSuccess = false,
        deleteError = null;

  OwnerProfileState copyWith({
    bool? loading,
    String? error,
    OwnerProfile? profile,
    bool? deletingAccount,
    bool? deleteSuccess,
    String? deleteError,
  }) {
    return OwnerProfileState(
      loading: loading ?? this.loading,
      error: error,
      profile: profile ?? this.profile,
      deletingAccount: deletingAccount ?? this.deletingAccount,
      deleteSuccess: deleteSuccess ?? this.deleteSuccess,
      deleteError: deleteError,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        profile,
        deletingAccount,
        deleteSuccess,
        deleteError,
      ];
}