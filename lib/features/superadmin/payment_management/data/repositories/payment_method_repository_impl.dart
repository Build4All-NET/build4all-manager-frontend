import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/i_payment_method_repository.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_api.dart';

class PaymentMethodRepositoryImpl implements IPaymentMethodRepository {
  final PaymentMethodApi _api;
  PaymentMethodRepositoryImpl(this._api);

  @override
  Future<List<PaymentMethod>> getAll() => _api.getAll();

  @override
  Future<void> create(PaymentMethod method) =>
      _api.create(PaymentMethodModel.fromEntity(method).toCreateBody());

  @override
  Future<void> update(PaymentMethod method) => _api.update(
        method.id,
        PaymentMethodModel.fromEntity(method).toUpdateBody(),
      );

  @override
  Future<void> toggle({required int id, required bool isEnabled}) =>
      _api.toggle(id, isEnabled);
}
