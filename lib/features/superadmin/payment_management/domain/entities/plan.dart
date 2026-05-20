import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String code;
  final String displayName;
  final int? usersAllowed;
  final bool requiresDedicatedServer;
  final int billingCycleMonths;

  const Plan({
    required this.code,
    required this.displayName,
    this.usersAllowed,
    required this.requiresDedicatedServer,
    required this.billingCycleMonths,
  });

  @override
  List<Object?> get props => [
        code,
        displayName,
        usersAllowed,
        requiresDedicatedServer,
        billingCycleMonths,
      ];
}
