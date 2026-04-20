import '../entities/payment_method.dart';
import '../repositories/i_payment_method_repository.dart';

class GetPaymentMethods {
  final IPaymentMethodRepository _repo;
  const GetPaymentMethods(this._repo);

  Future<List<PaymentMethod>> call() => _repo.getAll();
}
