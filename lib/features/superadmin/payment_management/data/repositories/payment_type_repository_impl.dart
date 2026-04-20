import '../../domain/entities/managed_payment_type.dart';
import '../../domain/repositories/i_payment_type_repository.dart';
import '../models/managed_payment_type_model.dart';
import '../services/payment_type_api.dart';

class PaymentTypeRepositoryImpl implements IPaymentTypeRepository {
  final PaymentTypeApi _api;
  PaymentTypeRepositoryImpl(this._api);

  @override
  Future<List<ManagedPaymentType>> getAll() => _api.getAll();

  @override
  Future<void> create(ManagedPaymentType type) =>
      _api.create(ManagedPaymentTypeModel.fromEntity(type).toCreateBody());

  @override
  Future<void> update(ManagedPaymentType type) => _api.update(
        type.id,
        ManagedPaymentTypeModel.fromEntity(type).toUpdateBody(),
      );

  @override
  Future<void> toggle({required int id, required bool isActive}) =>
      _api.toggle(id, isActive);
}
