import '../../domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.code,
    required super.displayName,
    super.usersAllowed,
    required super.requiresDedicatedServer,
    required super.billingCycleMonths,
  });

  factory PlanModel.fromJson(Map<String, dynamic> j) => PlanModel(
        code: (j['code'] ?? '').toString(),
        displayName: (j['displayName'] ?? j['name'] ?? '').toString(),
        usersAllowed: j['usersAllowed'] != null
            ? int.tryParse(j['usersAllowed'].toString())
            : null,
        requiresDedicatedServer:
            (j['requiresDedicatedServer'] ?? false) as bool,
        billingCycleMonths:
            int.tryParse((j['billingCycleMonths'] ?? 1).toString()) ?? 1,
      );

  factory PlanModel.fromEntity(Plan e) => PlanModel(
        code: e.code,
        displayName: e.displayName,
        usersAllowed: e.usersAllowed,
        requiresDedicatedServer: e.requiresDedicatedServer,
        billingCycleMonths: e.billingCycleMonths,
      );

  /// Used for POST (create) — includes code.
  Map<String, dynamic> toCreateBody() => {
        'code': code,
        'displayName': displayName,
        if (usersAllowed != null) 'usersAllowed': usersAllowed,
        'requiresDedicatedServer': requiresDedicatedServer,
        'billingCycleMonths': billingCycleMonths,
      };

  /// Used for PUT (update) — excludes code (immutable after creation).
  Map<String, dynamic> toUpdateBody() => {
        'displayName': displayName,
        if (usersAllowed != null) 'usersAllowed': usersAllowed,
        'requiresDedicatedServer': requiresDedicatedServer,
        'billingCycleMonths': billingCycleMonths,
      };
}
