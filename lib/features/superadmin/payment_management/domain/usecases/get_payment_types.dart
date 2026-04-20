import '../entities/managed_payment_type.dart';
import '../repositories/i_payment_type_repository.dart';

class GetPaymentTypes {
  final IPaymentTypeRepository _repo;
  const GetPaymentTypes(this._repo);

  Future<List<ManagedPaymentType>> call() => _repo.getAll();
}
