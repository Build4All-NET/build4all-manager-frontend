import '../entities/managed_payment_type.dart';
import '../repositories/i_payment_type_repository.dart';

class UpdatePaymentType {
  final IPaymentTypeRepository _repo;
  const UpdatePaymentType(this._repo);

  Future<void> call(ManagedPaymentType type) => _repo.update(type);
}
