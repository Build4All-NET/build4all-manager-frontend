import '../../domain/entities/owner_profile.dart';
import '../../domain/repositories/i_owner_profile_repository.dart';
import '../models/owner_profile_dto.dart';
import '../services/owner_profile_api.dart';

class OwnerProfileRepositoryImpl implements IOwnerProfileRepository {
  final OwnerProfileApi api;
  OwnerProfileRepositoryImpl(this.api);

  OwnerProfile _map(OwnerProfileDto d) => OwnerProfile(
        adminId: d.adminId,
        username: d.username,
        firstName: d.firstName,
        lastName: d.lastName,
        email: d.email,
        role: d.role,
        businessId: d.businessId,
        notifyItemUpdates: d.notifyItemUpdates ?? true,
        notifyUserFeedback: d.notifyUserFeedback ?? true,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        phoneNumber: d.phoneNumber,
      );

  @override
  Future<OwnerProfile> getMe() async => _map(await api.getMe());

  @override
  Future<OwnerProfile> getById(int adminId) async =>
      _map(await api.getById(adminId));
}
