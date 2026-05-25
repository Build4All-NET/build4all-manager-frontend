import 'package:flutter_test/flutter_test.dart';

import 'package:build4all_manager/features/owner/social/data/services/catalog_currency_compat.dart';

/// Mirrors the backend's `CatalogCurrencyCheckerTest`. Keeps the FE
/// warning identical to the BE pre-flight error so the OWNER sees the
/// same message either way.
void main() {
  group('matches', () {
    test('exact match returns null', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: 'USD', itemCurrency: 'USD'),
        isNull,
      );
    });

    test('case insensitive', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: 'usd', itemCurrency: 'USD'),
        isNull,
      );
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: 'EUR', itemCurrency: 'eur'),
        isNull,
      );
    });

    test('whitespace tolerated', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: '  USD ', itemCurrency: 'USD'),
        isNull,
      );
    });
  });

  group('mismatch', () {
    test('returns reason mentioning both codes', () {
      final r = CatalogCurrencyCompat.mismatchReason(
          catalogCurrency: 'USD', itemCurrency: 'EUR');
      expect(r, isNotNull);
      expect(r!, contains('USD'));
      expect(r, contains('EUR'));
    });
  });

  group('skips check (defer to backend)', () {
    test('null item currency', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: 'USD', itemCurrency: null),
        isNull,
      );
    });
    test('empty item currency', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: 'USD', itemCurrency: '   '),
        isNull,
      );
    });
    test('null catalog currency', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: null, itemCurrency: 'USD'),
        isNull,
      );
    });
    test('empty catalog currency', () {
      expect(
        CatalogCurrencyCompat.mismatchReason(
            catalogCurrency: '', itemCurrency: 'USD'),
        isNull,
      );
    });
  });
}
