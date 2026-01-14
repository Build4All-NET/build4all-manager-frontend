import 'package:flutter/material.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_text_field.dart';

class DecisionSheet {
  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required String hint,
    required String cancelLabel,
  }) async {
    final ctrl = TextEditingController();

    final future = showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: ctrl,
                label: hint,
                hint: hint,
                maxLines: 4,
                minLines: 3,
                filled: true,
              ),
              const SizedBox(height: 12),

              // ✅ lock height to avoid flex going crazy
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        type: AppButtonType.outline,
                        label: cancelLabel,
                        expand: true,
                        onPressed: () => Navigator.pop(ctx, null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        type: AppButtonType.primary,
                        label: confirmLabel,
                        expand: true,
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // ✅ dispose AFTER the sheet is completely gone
    return future.whenComplete(ctrl.dispose);
  }
}
