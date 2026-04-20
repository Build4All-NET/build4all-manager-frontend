import '../entities/managed_payment_type.dart';
import '../repositories/i_payment_type_repository.dart';

class CreatePaymentType {
  final IPaymentTypeRepository _repo;
  const CreatePaymentType(this._repo);

  Future<void> call(ManagedPaymentType type) => _repo.create(type);
}
