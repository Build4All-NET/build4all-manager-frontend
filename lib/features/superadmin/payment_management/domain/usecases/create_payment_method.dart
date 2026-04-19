import '../entities/payment_method.dart';
import '../repositories/i_payment_method_repository.dart';

class CreatePaymentMethod {
  final IPaymentMethodRepository _repo;
  const CreatePaymentMethod(this._repo);

  Future<void> call(PaymentMethod method) => _repo.create(method);
}
