import 'package:build4all_manager/features/auth/domain/entities/app_user.dart';
import 'package:build4all_manager/features/auth/domain/entities/auth_token.dart';
import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';
class OwnerCompleteProfileUseCase {
  final IAuthRepository repo;
  OwnerCompleteProfileUseCase(this.repo);

  Future<(AuthToken, AppUser)> call({
    required String registrationToken,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) =>
      repo.ownerCompleteProfile(
        registrationToken: registrationToken,
        username: username,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
}
