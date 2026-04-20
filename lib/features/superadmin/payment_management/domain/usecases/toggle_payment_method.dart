import '../repositories/i_payment_method_repository.dart';

class TogglePaymentMethod {
  final IPaymentMethodRepository _repo;
  const TogglePaymentMethod(this._repo);

  Future<void> call({required int id, required bool isEnabled}) =>
      _repo.toggle(id: id, isEnabled: isEnabled);
}
