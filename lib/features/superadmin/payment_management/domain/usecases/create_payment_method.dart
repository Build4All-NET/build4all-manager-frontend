import '../repositories/i_payment_method_repository.dart';

class CreatePaymentMethod {
  final IPaymentMethodRepository _repo;
  const CreatePaymentMethod(this._repo);

  Future<void> call({
    required String name,
    required String type,
    required String provider,
  }) =>
      _repo.create(name: name, type: type, provider: provider);
}
