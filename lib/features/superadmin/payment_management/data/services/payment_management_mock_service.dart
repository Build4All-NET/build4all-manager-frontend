import '../dto/payment_method_dto.dart';
import '../dto/payment_type_dto.dart';
import 'i_payment_management_service.dart';

// Swap into BLoC/repository wiring when backend is unavailable.
// Replace with PaymentManagementServiceImpl once the API is live.
class PaymentManagementMockService implements IPaymentManagementService {
  static const _delay = Duration(milliseconds: 600);

  // ── Mutable in-memory stores ─────────────────────────────────────────────

  final List<PaymentMethodResponseDto> _methods = [
    PaymentMethodResponseDto(
      id: 1,
      paymentDisplayName: 'Cash on Delivery',
      paymentType: 'CASH',
      providerCode: 'INTERNAL',
      description: 'Customer pays in cash upon delivery.',
      isEnabled: true,
      config: {'instructions': 'Please have exact change ready.'},
      createdAt: '2024-01-10T08:00:00.000Z',
    ),
    PaymentMethodResponseDto(
      id: 2,
      paymentDisplayName: 'PayPal',
      paymentType: 'PAYPAL',
      providerCode: 'PAYPAL',
      description: 'Pay securely via PayPal.',
      isEnabled: true,
      config: {
        'clientId': 'AaBbCcDdEe1234567890',
        'secret': '••••••••••••••••',
        'sandbox': false,
      },
      createdAt: '2024-01-12T09:30:00.000Z',
    ),
    PaymentMethodResponseDto(
      id: 3,
      paymentDisplayName: 'Stripe',
      paymentType: 'STRIPE',
      providerCode: 'STRIPE',
      description: 'Credit and debit cards via Stripe.',
      isEnabled: true,
      config: {
        'publishableKey': 'pk_live_xxxxxxxxxxxxxxxxxxxx',
        'secretKey': '••••••••••••••••',
      },
      createdAt: '2024-01-15T11:00:00.000Z',
    ),
    PaymentMethodResponseDto(
      id: 4,
      paymentDisplayName: 'VISA Direct',
      paymentType: 'VISA',
      providerCode: 'VISA',
      description: 'Direct VISA card processing.',
      isEnabled: false,
      config: {
        'merchantId': 'MERCH-001234',
        'terminalId': 'TERM-005678',
      },
      createdAt: '2024-02-01T14:00:00.000Z',
    ),
    PaymentMethodResponseDto(
      id: 5,
      paymentDisplayName: 'Bank Transfer',
      paymentType: 'BANK_TRANSFER',
      providerCode: 'INTERNAL',
      description: 'Direct bank transfer to company account.',
      isEnabled: true,
      config: {},
      createdAt: '2024-02-10T10:00:00.000Z',
    ),
  ];

  final List<PaymentTypeResponseDto> _types = [
    PaymentTypeResponseDto(
      id: 1,
      typeName: 'Cash',
      code: 'CASH',
      description: 'Physical cash payment.',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    PaymentTypeResponseDto(
      id: 2,
      typeName: 'PayPal',
      code: 'PAYPAL',
      description: 'PayPal online payment.',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    PaymentTypeResponseDto(
      id: 3,
      typeName: 'Stripe',
      code: 'STRIPE',
      description: 'Stripe card processing.',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    PaymentTypeResponseDto(
      id: 4,
      typeName: 'VISA',
      code: 'VISA',
      description: 'VISA direct processing.',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    PaymentTypeResponseDto(
      id: 5,
      typeName: 'Bank Transfer',
      code: 'BANK_TRANSFER',
      description: 'Direct bank wire transfer.',
      isActive: true,
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    PaymentTypeResponseDto(
      id: 6,
      typeName: 'Mobile Wallet',
      code: 'MOBILE_WALLET',
      description: 'Mobile wallet (e.g. Apple Pay, Google Pay).',
      isActive: false,
      createdAt: '2024-03-05T00:00:00.000Z',
    ),
  ];

  int _nextMethodId = 6;
  int _nextTypeId = 7;

  // ── Payment Methods ──────────────────────────────────────────────────────

  @override
  Future<List<PaymentMethodResponseDto>> getPaymentMethods() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_methods);
  }

  @override
  Future<PaymentMethodResponseDto> getPaymentMethodById(int id) async {
    await Future.delayed(_delay);
    return _methods.firstWhere(
      (m) => m.id == id,
      orElse: () => throw Exception('Payment method $id not found.'),
    );
  }

  @override
  Future<void> createPaymentMethod(CreatePaymentMethodDto dto) async {
    await Future.delayed(_delay);
    _methods.add(PaymentMethodResponseDto(
      id: _nextMethodId++,
      paymentDisplayName: dto.paymentDisplayName,
      paymentType: dto.paymentType,
      providerCode: dto.providerCode,
      description: dto.description,
      isEnabled: dto.isEnabled,
      config: dto.config,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  @override
  Future<void> updatePaymentMethod(
      int id, UpdatePaymentMethodDto dto) async {
    await Future.delayed(_delay);
    final idx = _methods.indexWhere((m) => m.id == id);
    if (idx == -1) throw Exception('Payment method $id not found.');
    final existing = _methods[idx];
    _methods[idx] = PaymentMethodResponseDto(
      id: existing.id,
      paymentDisplayName: dto.paymentDisplayName,
      paymentType: existing.paymentType,
      providerCode: dto.providerCode,
      description: dto.description,
      isEnabled: dto.isEnabled,
      config: dto.config,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<void> togglePaymentMethod(int id, bool isEnabled) async {
    await Future.delayed(_delay);
    final idx = _methods.indexWhere((m) => m.id == id);
    if (idx == -1) throw Exception('Payment method $id not found.');
    final existing = _methods[idx];
    _methods[idx] = PaymentMethodResponseDto(
      id: existing.id,
      paymentDisplayName: existing.paymentDisplayName,
      paymentType: existing.paymentType,
      providerCode: existing.providerCode,
      description: existing.description,
      isEnabled: isEnabled,
      config: existing.config,
      createdAt: existing.createdAt,
    );
  }

  // ── Payment Types ────────────────────────────────────────────────────────

  @override
  Future<List<PaymentTypeResponseDto>> getPaymentTypes() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_types);
  }

  @override
  Future<void> createPaymentType(CreatePaymentTypeDto dto) async {
    await Future.delayed(_delay);
    final codeUpper = dto.code.toUpperCase();
    if (_types.any((t) => t.code == codeUpper)) {
      throw Exception('A type with code "$codeUpper" already exists.');
    }
    _types.add(PaymentTypeResponseDto(
      id: _nextTypeId++,
      typeName: dto.typeName,
      code: codeUpper,
      description: dto.description,
      isActive: dto.isActive,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  @override
  Future<void> updatePaymentType(int id, UpdatePaymentTypeDto dto) async {
    await Future.delayed(_delay);
    final idx = _types.indexWhere((t) => t.id == id);
    if (idx == -1) throw Exception('Payment type $id not found.');
    final existing = _types[idx];
    _types[idx] = PaymentTypeResponseDto(
      id: existing.id,
      typeName: dto.typeName,
      code: existing.code,
      description: dto.description,
      isActive: dto.isActive,
      createdAt: existing.createdAt,
    );
  }
}
