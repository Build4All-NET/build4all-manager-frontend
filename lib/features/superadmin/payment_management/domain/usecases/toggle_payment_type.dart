import '../repositories/i_payment_type_repository.dart';

class TogglePaymentType {
  final IPaymentTypeRepository _repo;
  const TogglePaymentType(this._repo);

  Future<void> call({required int id, required bool isActive}) =>
      _repo.toggle(id: id, isActive: isActive);
}
