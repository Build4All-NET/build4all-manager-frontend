import '../entities/payment_method.dart';

abstract class IPaymentMethodRepository {
  Future<List<PaymentMethod>> getAll();
  Future<void> create(PaymentMethod method);
  Future<void> update(PaymentMethod method);
  Future<void> toggle({required int id, required bool isEnabled});
}
