import '../entities/managed_payment_type.dart';

abstract class IPaymentTypeRepository {
  Future<List<ManagedPaymentType>> getAll();
  Future<void> create(ManagedPaymentType type);
  Future<void> update(ManagedPaymentType type);
  Future<void> toggle({required int id, required bool isActive});
}
