import '../repositories/i_payment_method_repository.dart';

class UpdatePaymentMethod {
  final IPaymentMethodRepository _repo;
  const UpdatePaymentMethod(this._repo);

  Future<void> call({
    required int id,
    required String name,
    required String type,
    required String provider,
  }) =>
      _repo.update(id: id, name: name, type: type, provider: provider);
}
