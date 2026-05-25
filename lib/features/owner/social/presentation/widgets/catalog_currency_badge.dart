import 'package:flutter/material.dart';

import '../../data/services/catalog_currency_compat.dart';

/// Chip widget the product editor renders for each connected catalog
/// channel. Green check when the product's currency matches the catalog's;
/// red warning chip with a tappable bottom sheet otherwise.
class CatalogCurrencyBadge extends StatelessWidget {
  final String catalogName;
  final String? catalogCurrency;
  final String? itemCurrency;

  const CatalogCurrencyBadge({
    super.key,
    required this.catalogName,
    required this.catalogCurrency,
    required this.itemCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reason = CatalogCurrencyCompat.mismatchReason(
      catalogCurrency: catalogCurrency,
      itemCurrency: itemCurrency,
    );
    if (reason == null) {
      final tooltip = (catalogCurrency == null || catalogCurrency!.isEmpty)
          ? 'Catalog currency not configured — defer to backend'
          : '$catalogName is in ${catalogCurrency!.toUpperCase()}';
      return Tooltip(
        message: tooltip,
        child: Chip(
          avatar: Icon(Icons.check_circle, color: scheme.primary, size: 16),
          label: Text('$catalogName OK'),
          labelStyle: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
          visualDensity: VisualDensity.compact,
          backgroundColor: scheme.primary.withOpacity(0.10),
          side: BorderSide(color: scheme.primary.withOpacity(0.25)),
        ),
      );
    }
    return Tooltip(
      message: reason,
      child: ActionChip(
        avatar: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 16),
        label: Text('$catalogName currency mismatch'),
        labelStyle: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
        visualDensity: VisualDensity.compact,
        backgroundColor: scheme.error.withOpacity(0.08),
        side: BorderSide(color: scheme.error.withOpacity(0.25)),
        onPressed: () => _showSheet(context, reason),
      ),
    );
  }

  void _showSheet(BuildContext context, String reason) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Currency mismatch',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            Text(reason, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Meta\'s catalog API silently drops items whose currency does '
              'not match the catalog. Switch the product to the catalog\'s '
              'currency, or connect a separate catalog for this currency.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
