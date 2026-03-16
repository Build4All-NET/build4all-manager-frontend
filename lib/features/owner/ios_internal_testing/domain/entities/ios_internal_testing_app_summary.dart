import 'ios_internal_testing_request.dart';

class IosInternalTestingAppSummary {
  final List<IosInternalTestingRequest> requests;
  final int usedSlots;
  final int maxSlots;

  const IosInternalTestingAppSummary({
    required this.requests,
    required this.usedSlots,
    required this.maxSlots,
  });

  bool get isFull => usedSlots >= maxSlots;

  int get remainingSlots {
    final remaining = maxSlots - usedSlots;
    return remaining < 0 ? 0 : remaining;
  }

  bool get hasRequests => requests.isNotEmpty;
}