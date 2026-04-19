import '../dto/payment_method_dto.dart';
import '../dto/payment_type_dto.dart';

abstract class IPaymentManagementService {
  // ── Payment Methods ──────────────────────────────────────────────────────
  Future<List<PaymentMethodResponseDto>> getPaymentMethods();
  Future<PaymentMethodResponseDto> getPaymentMethodById(int id);
  Future<void> createPaymentMethod(CreatePaymentMethodDto dto);
  Future<void> updatePaymentMethod(int id, UpdatePaymentMethodDto dto);
  Future<void> togglePaymentMethod(int id, bool isEnabled);

  // ── Payment Types ────────────────────────────────────────────────────────
  Future<List<PaymentTypeResponseDto>> getPaymentTypes();
  Future<void> createPaymentType(CreatePaymentTypeDto dto);
  Future<void> updatePaymentType(int id, UpdatePaymentTypeDto dto);
  Future<void> togglePaymentType(int id, bool isActive);
}
