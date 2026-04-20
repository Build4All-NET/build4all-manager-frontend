import 'package:equatable/equatable.dart';

import '../../domain/entities/license_plan_pricing.dart';

abstract class LicensePlanPricingEvent extends Equatable {
  const LicensePlanPricingEvent();

  @override
  List<Object?> get props => [];
}

class LoadLicensePlanPricings extends LicensePlanPricingEvent {}

class RefreshLicensePlanPricings extends LicensePlanPricingEvent {}

class AddLicensePlanPricing extends LicensePlanPricingEvent {
  final LicensePlanPricing pricing;
  const AddLicensePlanPricing(this.pricing);

  @override
  List<Object?> get props => [pricing];
}

class EditLicensePlanPricing extends LicensePlanPricingEvent {
  final LicensePlanPricing pricing;
  const EditLicensePlanPricing(this.pricing);

  @override
  List<Object?> get props => [pricing];
}

class ToggleLicensePlanPricingActive extends LicensePlanPricingEvent {
  final int id;
  final bool isActive;
  const ToggleLicensePlanPricingActive({
    required this.id,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, isActive];
}
