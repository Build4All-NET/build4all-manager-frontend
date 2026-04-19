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
  Future<void> create({
    required String name,
    required String type,
    required String provider,
  }) =>
      _api.create(
        PaymentMethodModel(
          id: 0,
          name: name,
          type: type,
          provider: provider,
          enabled: true,
        ).toCreateBody(),
      );

  @override
  Future<void> update({
    required int id,
    required String name,
    required String type,
    required String provider,
  }) =>
      _api.update(
        id,
        PaymentMethodModel(
          id: id,
          name: name,
          type: type,
          provider: provider,
          enabled: true,
        ).toUpdateBody(),
      );

  @override
  Future<void> toggle({required int id, required bool enabled}) =>
      _api.toggle(id, enabled);
}
