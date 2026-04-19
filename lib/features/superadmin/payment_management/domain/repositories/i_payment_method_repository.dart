import '../entities/payment_method.dart';

abstract class IPaymentMethodRepository {
  Future<List<PaymentMethod>> getAll();

  Future<void> create({
    required String name,
    required String type,
    required String provider,
  });

  Future<void> update({
    required int id,
    required String name,
    required String type,
    required String provider,
  });

  Future<void> toggle({required int id, required bool enabled});
}
