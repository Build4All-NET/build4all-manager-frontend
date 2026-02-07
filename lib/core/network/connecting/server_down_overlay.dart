import 'package:flutter/material.dart';
import '../server_status_controller.dart';

class ServerDownOverlay extends StatelessWidget {
  const ServerDownOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServerUiStatus>(
      valueListenable: ServerStatusController.status,
      builder: (context, st, _) {
        if (st != ServerUiStatus.down) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Stack(
          children: [
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: theme.colorScheme.surface,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: theme.colorScheme.error,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Server unavailable',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Still can't reach the server.\nThis will close automatically once it’s back.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.8),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: ServerStatusController.checkNow,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
