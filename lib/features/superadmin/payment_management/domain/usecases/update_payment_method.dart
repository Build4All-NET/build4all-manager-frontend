import '../entities/payment_method.dart';
import '../repositories/i_payment_method_repository.dart';

class UpdatePaymentMethod {
  final IPaymentMethodRepository _repo;
  const UpdatePaymentMethod(this._repo);

  Future<void> call(PaymentMethod method) => _repo.update(method);
}
