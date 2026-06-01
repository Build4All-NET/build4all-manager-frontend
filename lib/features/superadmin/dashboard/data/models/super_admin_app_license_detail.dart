import 'super_admin_app_license_row.dart';

/// Rich single-app payload from
/// GET /api/licensing/apps/{aupId}/license-detail — the summary row plus the
/// subscription timeline and the payment-history ledger.
class SuperAdminAppLicenseDetail {
  final SuperAdminAppLicenseRow summary;
  final List<LicensePeriod> subscriptions;
  final List<LicensePayment> payments;

  const SuperAdminAppLicenseDetail({
    required this.summary,
    this.subscriptions = const [],
    this.payments = const [],
  });

  factory SuperAdminAppLicenseDetail.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'];
    final subs = json['subscriptions'];
    final pays = json['payments'];

    return SuperAdminAppLicenseDetail(
      summary: SuperAdminAppLicenseRow.fromJson(
        summaryJson is Map<String, dynamic> ? summaryJson : <String, dynamic>{},
      ),
      subscriptions: subs is List
          ? subs
              .whereType<Map<String, dynamic>>()
              .map(LicensePeriod.fromJson)
              .toList()
          : const [],
      payments: pays is List
          ? pays
              .whereType<Map<String, dynamic>>()
              .map(LicensePayment.fromJson)
              .toList()
          : const [],
    );
  }
}

class LicensePeriod {
  final String? planCode;
  final String? planName;
  final String? status;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const LicensePeriod({
    this.planCode,
    this.planName,
    this.status,
    this.periodStart,
    this.periodEnd,
  });

  factory LicensePeriod.fromJson(Map<String, dynamic> json) {
    return LicensePeriod(
      planCode: json['planCode']?.toString(),
      planName: json['planName']?.toString(),
      status: json['status']?.toString(),
      periodStart: _date(json['periodStart']),
      periodEnd: _date(json['periodEnd']),
    );
  }
}

class LicensePayment {
  final DateTime? date;
  final String? planCode;
  final String? billingCycle;
  final String? provider;
  final String? status;
  final double? amount;
  final String? currency;

  const LicensePayment({
    this.date,
    this.planCode,
    this.billingCycle,
    this.provider,
    this.status,
    this.amount,
    this.currency,
  });

  factory LicensePayment.fromJson(Map<String, dynamic> json) {
    double? parseAmount(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LicensePayment(
      date: _date(json['date']),
      planCode: json['planCode']?.toString(),
      billingCycle: json['billingCycle']?.toString(),
      provider: json['provider']?.toString(),
      status: json['status']?.toString(),
      amount: parseAmount(json['amount']),
      currency: json['currency']?.toString(),
    );
  }
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
