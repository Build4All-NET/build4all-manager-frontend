/// Local mirror of the backend's `CatalogCurrencyChecker`. Lets the
/// product editor warn the OWNER as soon as they pick a catalog channel
/// whose currency differs from the product's, before any sync attempt.
///
/// Keep behaviour in sync with
/// `com.build4all.socialMedia.publisher.meta.CatalogCurrencyChecker`.
class CatalogCurrencyCompat {
  /// @return null when compatible (or unknowable — defer to the backend),
  ///         or a short reason string when the currencies definitely
  ///         disagree.
  static String? mismatchReason({
    required String? catalogCurrency,
    required String? itemCurrency,
  }) {
    if (itemCurrency == null || itemCurrency.trim().isEmpty) return null;
    if (catalogCurrency == null || catalogCurrency.trim().isEmpty) return null;

    final a = catalogCurrency.trim().toUpperCase();
    final b = itemCurrency.trim().toUpperCase();
    if (a == b) return null;
    return 'Product currency $b does not match catalog currency $a';
  }
}
